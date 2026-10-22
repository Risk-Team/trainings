# =============================================================================
# CAVA training - complete installation setup for RStudio (Windows)
# =============================================================================
# Assumes Java (JDK) and Rtools are already installed from the browser.
# Run section by section (Ctrl+Enter) or source the whole file.
# Takes roughly 15 minutes the first time.
# =============================================================================

options(repos = c(CRAN = "https://cloud.r-project.org"))

# -----------------------------------------------------------------------------
# 1. Check R and build tools
# -----------------------------------------------------------------------------
cat("\n--- 1. R and build tools ---\n")
print(R.version.string)

if (getRversion() < "4.1.0") {
  warning("R is older than 4.1. Please update R before continuing.")
}

make_path <- Sys.which("make")
if (nzchar(make_path)) {
  cat("Rtools found: ", make_path, "\n")
} else {
  warning("Rtools not found on PATH. Install the Rtools version matching your R ",
          "version, then restart RStudio.")
}

# -----------------------------------------------------------------------------
# 2. Install and check the spatial packages (terra, sf)
#    On Windows these install as pre-built binaries from CRAN.
# -----------------------------------------------------------------------------
cat("\n--- 2. Spatial packages (terra, sf) ---\n")

for (p in c("terra", "sf")) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, type = "binary")
  }
}

library(terra)
library(sf)
cat("terra", as.character(packageVersion("terra")), "| sf",
    as.character(packageVersion("sf")), "- OK\n")

# -----------------------------------------------------------------------------
# 3. Check Java / rJava (CAVAanalytics depends on it)
# -----------------------------------------------------------------------------
cat("\n--- 3. Java / rJava ---\n")

if (!requireNamespace("rJava", quietly = TRUE)) {
  install.packages("rJava", type = "binary")
}

# Match the 64-bit R with a 64-bit JDK. If this fails, set JAVA_HOME first, e.g.:
# Sys.setenv(JAVA_HOME = "C:/Program Files/Eclipse Adoptium/jdk-17.0.x-hotspot")
res <- tryCatch({
  library(rJava)
  .jinit()
  cat("Java version:", .jcall("java/lang/System", "S", "getProperty", "java.version"), "\n")
  cat("rJava OK\n")
  TRUE
}, error = function(e) {
  message("rJava failed to load: ", conditionMessage(e))
  message("Check that a 64-bit JDK is installed and JAVA_HOME points to it, ",
          "then restart R and rerun this section.")
  FALSE
})
if (!res) stop("Fix rJava before continuing.")

# -----------------------------------------------------------------------------
# 4. Install pak
# -----------------------------------------------------------------------------
if (!requireNamespace("pak", quietly = TRUE)) install.packages("pak")

# -----------------------------------------------------------------------------
# 5. Install CAVAanalytics (official repo: un-fao/CAVAanalytics)
#    Note the lowercase "a" in "Analytics" is not a typo - use the name as shown.
# -----------------------------------------------------------------------------
cat("\n--- 5. Installing CAVAanalytics ---\n")
pak::pak("un-fao/CAVAanalytics")

# -----------------------------------------------------------------------------
# 6. Verify CAVAanalytics
# -----------------------------------------------------------------------------
cat("\n--- 6. Verify CAVAanalytics ---\n")

library(CAVAanalytics)
print(packageVersion("CAVAanalytics"))

# -----------------------------------------------------------------------------
# 7. Final complete verification
# -----------------------------------------------------------------------------
cat("\n--- 7. Final check ---\n")

print(R.version.string)

loaded <- vapply(
  c("terra", "sf", "rJava", "remotes", "CAVAanalytics"),
  function(p) requireNamespace(p, quietly = TRUE),
  logical(1)
)
print(loaded)

if (all(loaded)) {
  cat("All CAVA packages loaded successfully!\n")
  print(packageVersion("CAVAanalytics"))
} else {
  warning("These packages did not load: ", paste(names(loaded)[!loaded], collapse = ", "))
}
