## PPA Desktop Rserve bootstrap
## This script is sourced once when the Rserve container starts.
## It defines safer wrappers for reading Stata (.dta) and CSV files
## that are used transparently by the Java side when it calls
## library('foreign'); read.dta(...); read.csv(...).

safe_read_dta <- function(file, convert.factors = FALSE, ...) {
  # Prefer modern Stata readers that support Stata 13+.
  if (requireNamespace("readstata13", quietly = TRUE)) {
    df <- readstata13::read.dta13(
      file,
      convert.factors = convert.factors,
      generate.factors = FALSE,
      ...
    )
    return(as.data.frame(df))
  }

  # Fallback to the legacy foreign::read.dta implementation
  foreign::read.dta(file, convert.factors = convert.factors, ...)
}

# Place wrapper in the global environment so it masks foreign::read.dta
# even after library('foreign') is called by the application.
assign("read.dta", safe_read_dta, envir = .GlobalEnv)


safe_read_csv <- function(file, ...) {
  # Delegate to the base R implementation; this hook exists mainly so
  # we can tighten behaviour later if needed without touching Java.
  utils::read.csv(file, ...)
}

assign("read.csv", safe_read_csv, envir = .GlobalEnv)

# The Java side currently wraps reads in `local({ ... })` and then
# checks `exists('df')` / `colnames(df)` in subsequent R calls.
# In base R, variables assigned with `<-` inside `local()` do NOT persist
# in `.GlobalEnv`, which makes those follow-up checks fail.
#
# To keep behaviour compatible with the app (and older deployments),
# we override `local()` to evaluate the block in `.GlobalEnv`.
safe_local <- function(expr, envir = parent.frame(), ...) {
  base::eval(substitute(expr), envir = .GlobalEnv)
}

assign("local", safe_local, envir = .GlobalEnv)

