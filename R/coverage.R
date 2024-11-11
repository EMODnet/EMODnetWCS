#' Get a coverage from an EMODnet WCS Service
#'
#' @inheritParams emdn_get_coverage_info
#' @param coverage_id character string. Coverage ID.
#' @param bbox a named numeric vector of length 4, with names `xmin`, `ymin`,
#' `xmax` and `ymax`. specifying the bounding box.
#' (extent) of the raster to be returned.
#' @param crs the CRS of the supplied bounding box. Leave as `NULL` (default) if
#' same as coverage crs.
#' @param time for coverages that include a temporal dimension,
#' a vector of temporal coefficients specifying the
#' time points for which coverage data should be returned.
#' If `NULL` (default), the last time point is returned.
#' To get a list of all available temporal coefficients,
#' see [`emdn_get_coverage_dim_coefs`]. For a single time point, a
#' `SpatRaster` is returned. For more than one time points, `SpatRaster` stack
#' is returned.
#' @param elevation for coverages that include a vertical dimension,
#' a vector of vertical coefficients specifying the
#' elevation for which coverage data should be returned.
#' If `NULL` (default), the last elevation is returned.
#' To get a list of all available vertical coefficients,
#' see [`emdn_get_coverage_dim_coefs`]. For a single elevation, a
#' `SpatRaster` is returned. For more than one elevation, `SpatRaster` stack
#' is returned.
#' @param format the format of the file the coverage should be written out to.
#' @param rangesubset character vector of band descriptions to subset.
#' @param filename the file name to write to.
#' @param nil_values_as_na logical. Should raster nil values be converted to `NA`?
#'
#' @return an object of class [`terra::SpatRaster`]. The function also
#' writes the coverage to a local file.
#' @export
#'
#' @examples
#' \dontrun{
#' wcs <- emdn_init_wcs_client(service = "biology")
#' coverage_id <- "Emodnetbio__cal_fin_19582016_L1_err"
#' # Subset using a bounding box
#' emdn_get_coverage(wcs,
#'   coverage_id = coverage_id,
#'   bbox = c(
#'     xmin = 0, ymin = 40,
#'     xmax = 5, ymax = 45
#'   )
#' )
#' # Subset using a bounding box and specific timepoints
#' emdn_get_coverage(wcs,
#'   coverage_id = coverage_id,
#'   bbox = c(
#'     xmin = 0, ymin = 40,
#'     xmax = 5, ymax = 45
#'   ),
#'   time = c(
#'     "1963-11-16T00:00:00.000Z",
#'     "1964-02-16T00:00:00.000Z"
#'   )
#' )
#' # Subset using a bounding box and a specific band
#' emdn_get_coverage(wcs,
#'   coverage_id = coverage_id,
#'   bbox = c(
#'     xmin = 0, ymin = 40,
#'     xmax = 5, ymax = 45
#'   ),
#'   rangesubset = "Relative abundance"
#' )
#' }
emdn_get_coverage <- function(wcs = NULL, service = NULL,
                              coverage_id,
                              service_version = c(
                                "2.0.1", "2.1.0", "2.0.0",
                                "1.1.1", "1.1.0"
                              ),
                              logger = c("NONE", "INFO", "DEBUG"),
                              bbox = NULL, crs = NULL,
                              time = NULL,
                              elevation = NULL,
                              format = NULL,
                              rangesubset = NULL,
                              filename = NULL,
                              nil_values_as_na = FALSE,
                              check = TRUE) {
  if (is.null(wcs) & is.null(service)) {
    cli::cli_abort(c(
      "x" =
        "Please provide a valid {.var service}
        name or {.cls WCSClient} object to {.var wcs}.
        Both cannot be {.val NULL}"
    ))
  }

  if (is.null(wcs)) {
    wcs <- emdn_init_wcs_client(service, service_version, logger)
  }

  check_wcs(wcs)
  check_wcs_version(wcs)

  checkmate::assert_character(coverage_id, len = 1)
  check_coverages(wcs, coverage_id)
  ows_bbox <- validate_bbox(bbox)

  summary <- emdn_get_coverage_summaries(wcs, coverage_id)[[1]]

  # validate request arguments
  if (!is.null(rangesubset)) {
    validate_rangesubset(summary, rangesubset)
    rangesubset_encoded <- utils::URLencode(rangesubset) %>%
      paste(collapse = ",")
  } else {
    rangesubset_encoded <- NULL
    rangesubset <- emdn_get_band_descriptions(summary)
  }
  if (!is.null(time)) {
    validate_dimension_subset(wcs,
      coverage_id,
      type = "temporal",
      subset = time
    )
  }
  if (!is.null(elevation)) {
    validate_dimension_subset(wcs,
      coverage_id,
      type = "vertical",
      subset = elevation
    )
  }
  if (check) check_cov_contains_bbox(summary, bbox, crs)

  cli::cli_rule(left = "Downloading coverage {.val {coverage_id}}")

  coverage_id <- validate_namespace(coverage_id)

  if (length(time) > 1 || length(elevation) > 1) {

    # TODO - uncomment crs when https://github.com/eblondel/ows4R/issues/90
    # is resolved
    cov_raster <- summary$getCoverageStack(
      bbox = ows_bbox,
      crs = crs,
      time = time,
      format = format,
      rangesubset = rangesubset_encoded,
      filename = filename
    )
    cli::cli_text()
    cli::cli_alert_success(
      "\n Coverage {.val {coverage_id}} downloaded succesfully as a
        {.pkg terra} {.cls SpatRaster} Stack"
    )
  } else {
    cov_raster <- summary$getCoverage(
      bbox = ows_bbox,
      crs = crs,
      time = time,
      elevation = elevation,
      format = format,
      rangesubset = rangesubset_encoded,
      filename = filename
    )
    cli::cli_text()
    cli::cli_alert_success(
      "\n Coverage {.val {coverage_id}} downloaded succesfully as a
        {.pkg terra} {.cls SpatRaster}"
    )
  }


  if (nil_values_as_na) {
    # convert nil_values to NA
    cov_raster <- conv_nil_to_na(
      cov_raster,
      summary,
      rangesubset
    )
  }

  cov_raster
}

# Convert coverage nil values to NA
conv_nil_to_na <- function(cov_raster, summary, rangesubset) {
  nil_values <- emdn_get_band_nil_values(summary)[rangesubset]
  uniq_nil_val <- unique(nil_values)

  # For efficiency, replace nil_values across entire coverage if all bands have
  # the same nil_values. Return early.
  if (length(uniq_nil_val) == 1L) {
    if (is.numeric(uniq_nil_val)) {
      terra::values(cov_raster)[
        terra::values(cov_raster) >= uniq_nil_val
      ] <- NA

      cli::cli_alert_success(
        "nil values {.val {uniq_nil_val}} converted to {.field NA} on all bands."
      )
    } else {
      cli::cli_warn(
        "!" = "Cannot convert non numeric nil value {.val {uniq_nil_val}} to NA"
      )
    }
    return(cov_raster)
  }

  # If nil_values differ between bands, replace nil_values individually.
  n_bands <- terra::nlyr(cov_raster)
  nil_values <- rep(nil_values,
    times = n_bands / length(nil_values)
  )

  for (band_idx in 1:n_bands) {
    nil_value <- nil_values[[band_idx]]
    band_name <- names(nil_values)[band_idx]

    if (is.numeric(nil_value)) {
      cov_raster[[band_idx]][cov_raster[[band_idx]] >= nil_value] <- NA

      cli::cli_alert_success(
        "nil values {.val {nil_value}} converted to
        {.field NA} on band {.val {band_name}}"
      )
    } else {
      cli::cli_warn(
        "!" = "Cannot convert non numeric nil value {.val {nil_value}} to NA
          on band {.val {band_name}}"
      )
    }
  }

  return(cov_raster)
}
