# scoringutils' pairwise relative-skill calc invokes `wilcox.test` on score
# pairs and emits a `cannot compute exact p-value with ties` warning every
# time the values include ties. The ecfh test oracle ties heavily, so a
# single relative-skill scoring pass surfaces ~18 of these per run, cluttering
# test output without indicating any real problem. This helper muffles only
# that warning class so other warnings still surface as test failures.
# See #43.
suppress_wilcox_ties_warnings <- function(expr) {
  withCallingHandlers(
    expr,
    warning = function(w) {
      if (
        grepl(
          "cannot compute exact p-value with ties",
          conditionMessage(w)
        )
      ) {
        invokeRestart("muffleWarning")
      }
    }
  )
}
