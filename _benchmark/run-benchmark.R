# Run generate_eval_data() against the FluSight hub with the trimmed benchmark
# config, and report wall-clock, memory and a load/score/write split.
#
# Usage:
#   HUBPREDEVALS_BENCHMARK_HUB=/path/to/FluSight-forecast-hub \
#     Rscript _benchmark/run-benchmark.R
#
# For true peak RSS (the number that decides whether a change fits the runner's
# memory), wrap the call:
#   /usr/bin/time -l Rscript _benchmark/run-benchmark.R

benchmark_dir <- dirname(
  sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE))
)
pkg_dir <- dirname(benchmark_dir)

hub_path <- Sys.getenv("HUBPREDEVALS_BENCHMARK_HUB")
if (hub_path == "") {
  stop(
    "Set HUBPREDEVALS_BENCHMARK_HUB to a local FluSight-forecast-hub clone.",
    call. = FALSE
  )
}
if (!dir.exists(file.path(hub_path, "model-output"))) {
  stop("No model-output/ under ", hub_path, call. = FALSE)
}

config_path <- file.path(benchmark_dir, "predevals-config.yml")

# A checkout's git id: branch@sha, with -dirty when the working tree has
# uncommitted changes. The dirty marker is the honest signal that a run isn't
# reproducible from the sha alone, which is the load_all-uncommitted case.
git_id <- function(dir) {
  branch <- system2(
    "git",
    c("-C", dir, "rev-parse", "--abbrev-ref", "HEAD"),
    stdout = TRUE
  )
  sha <- system2(
    "git",
    c("-C", dir, "rev-parse", "--short", "HEAD"),
    stdout = TRUE
  )
  dirty <- length(system2(
    "git",
    c("-C", dir, "status", "--porcelain"),
    stdout = TRUE
  )) >
    0
  paste0(branch, "@", sha, if (dirty) "-dirty" else "")
}

# Human-readable run label: name a run after the change under test. Defaults to
# this package's git id.
label <- Sys.getenv("HUBPREDEVALS_BENCHMARK_LABEL")
if (label == "") {
  label <- git_id(pkg_dir)
}

# Most of the runtime lives in the dependencies, not this package: hubEvals
# (P2/P3) and scoringutils (pairwise-comparison merging, hubEvals#144). To
# benchmark a change in either, point these env vars at a local checkout of it;
# unset, the installed version is used. Loading in dependency order means a dev
# scoringutils runs under a dev hubEvals under this package's working tree.
load_dev_dep <- function(env_var) {
  src <- Sys.getenv(env_var)
  if (src == "") {
    return(NULL)
  }
  if (!dir.exists(src)) {
    stop(env_var, " set but not a directory: ", src, call. = FALSE)
  }
  pkgload::load_all(src, quiet = TRUE)
  src
}
scoringutils_src <- load_dev_dep("HUBPREDEVALS_BENCHMARK_SCORINGUTILS")
hubevals_src <- load_dev_dep("HUBPREDEVALS_BENCHMARK_HUBEVALS")

pkgload::load_all(pkg_dir, quiet = TRUE)

# Record what was measured for each dependency: a dev checkout as its git id
# (branch@sha[-dirty]); an installed package as version@sha from the RemoteSha
# pak/remotes bakes into DESCRIPTION, degrading to the bare version only for a
# plain install that carries no sha.
dep_id <- function(pkg, src) {
  if (!is.null(src)) {
    return(git_id(src))
  }
  version <- as.character(utils::packageVersion(pkg))
  sha <- utils::packageDescription(pkg)$RemoteSha
  # RemoteSha may hold a tag/ref ("2.2.0") rather than a commit; only append a
  # real hex sha, otherwise the version string already says it all.
  if (is.null(sha) || is.na(sha) || !grepl("^[0-9a-f]{7,40}$", sha)) {
    version
  } else {
    paste0(version, "@", substr(sha, 1, 7))
  }
}
hubevals_id <- dep_id("hubEvals", hubevals_src)
scoringutils_id <- dep_id("scoringutils", scoringutils_src)

out_path <- file.path(tempdir(), "benchmark-out")
dir.create(out_path, showWarnings = FALSE)
prof_path <- file.path(benchmark_dir, "Rprof.out")

# Baselines to measure against. gc(reset = TRUE) resets the max-used counters;
# the Arrow pool is tracked separately because Arrow allocates off the R heap
# and so is invisible to gc().
invisible(gc(reset = TRUE))
invisible(arrow::default_memory_pool()$max_memory) # touch pool before timing

cat("hub:          ", hub_path, "\n")
cat("config:       ", config_path, "\n")
cat("label:        ", label, "\n")
cat("hubEvals:     ", hubevals_id, "\n")
cat("scoringutils: ", scoringutils_id, "\n\n")

Rprof(prof_path, interval = 0.02, memory.profiling = FALSE)
elapsed <- system.time(
  generate_eval_data(
    hub_path = hub_path,
    config_path = config_path,
    out_path = out_path
  )
)
Rprof(NULL)

gc_result <- gc()
r_peak_mb <- sum(gc_result[, "max used"] * c(56, 8)) / 1024^2
arrow_peak_mb <- arrow::default_memory_pool()$max_memory / 1024^2

cat("\n=== ", label, " ===\n")
cat("wall-clock (s):   ", round(elapsed[["elapsed"]], 1), "\n")
cat("R heap peak (MB): ", round(r_peak_mb), "\n")
cat("Arrow peak (MB):  ", round(arrow_peak_mb), "\n")

prof <- summaryRprof(prof_path)$by.total
prof <- prof[prof$total.pct >= 1, c("total.time", "total.pct", "self.pct")]
cat("\n=== profile (>=1% of total time) ===\n")
print(utils::head(prof, 40))

results_path <- file.path(benchmark_dir, "results.csv")
result_row <- data.frame(
  label = label,
  hubevals = hubevals_id,
  scoringutils = scoringutils_id,
  elapsed_s = round(elapsed[["elapsed"]], 1),
  r_peak_mb = round(r_peak_mb),
  arrow_peak_mb = round(arrow_peak_mb),
  sysname = Sys.info()[["sysname"]],
  machine = Sys.info()[["machine"]],
  r_version = paste0(R.version$major, ".", R.version$minor)
)
write.table(
  result_row,
  results_path,
  sep = ",",
  row.names = FALSE,
  col.names = !file.exists(results_path),
  append = file.exists(results_path)
)
cat("\nAppended to", results_path, "\n")
