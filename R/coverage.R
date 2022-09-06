#' Get a coverage from an EMODnet WCS Service
#'
#' @inheritParams emodnet_get_wcs_coverage_info
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
#' see [`emodnet_get_coverage_dim_coefs`]. For a single time point, a
#' `SpatRaster` is returned. For more than one time points, `SpatRaster` stack
#' is returned.
#' @param elevation for coverages that include a vertical dimension,
#' a vector of vertical coefficients specifying the
#' elevation for which coverage data should be returned.
#' If `NULL` (default), the last elevation is returned.
#' To get a list of all available vertical coefficients,
#' see [`emodnet_get_coverage_dim_coefs`]. For a single elevation, a
#' `SpatRaster` is returned. For more than one elevation, `SpatRaster` stack
#' is returned.
#' @param format the format of the file the coverage should be written out to.
#' @param rangesubset character vector of band names to subset.
#' @param filename the file name to write to.
#' @param nil_values_as_na logical. Should raster nil values be converted to `NA`?
#'
#' @return an object of class [`terra::SpatRaster`]. The function also
#' writes the coverage to a local file.
#' @export
#'
#' @examples
#' \dontrun{
#' wcs <- emodnet_init_wcs_client(service = "biology")
#' coverage_id <- "Emodnetbio__cal_fin_19582016_L1_err"
#' # Subset using a bounding box
#' emodnet_get_wcs_coverage(wcs,
#'                          coverage_id = coverage_id,
#'                          bbox = c(xmin = 0, ymin = 40,
#'                                   xmax = 5, ymax = 45))
#' # Subset using a bounding box and specific timepoints
#' emodnet_get_wcs_coverage(wcs,
#'                          coverage_id = coverage_id,
#'                          bbox = c(xmin = 0, ymin = 40,
#'                                   xmax = 5, ymax = 45),
#'                          time = c("1963-11-16T00:00:00.000Z",
#'                                   "1964-02-16T00:00:00.000Z"))
#' # Subset using a bounding box and a specific band
#' emodnet_get_wcs_coverage(wcs,
#'                          coverage_id = coverage_id,
#'                          bbox = c(xmin = 0, ymin = 40,
#'                                   xmax = 5, ymax = 45),
#'                                   rangesubset = "Relative abundance")
#' }
emodnet_get_wcs_coverage <- function(wcs = NULL, service = NULL,
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
                                     nil_values_as_na = FALSE) {

    if (is.null(wcs) & is.null(service)) {
        cli::cli_abort(c("x" =
        "Please provide a valid {.var service}
        name or {.cls WCSClient} object to {.var wcs}.
        Both cannot be {.val NULL}"))
    }

    if (is.null(wcs)) {
        wcs <- emodnet_init_wcs_client(service, service_version, logger)
    }

    check_wcs(wcs)
    check_wcs_version(wcs)

    checkmate::assert_character(coverage_id, len = 1)
    check_coverages(wcs, coverage_id)
    ows_bbox <- validate_bbox(bbox)

    summary <- get_cov_summaries(wcs, coverage_id)[[1]]

    # validate request arguments
    if (!is.null(rangesubset)) {
        # TODO - uncomment validate(rangesubset) when
        # https://github.com/eblondel/ows4R/issues/80
        # is resolved
        # validate_rangesubset(summary, rangesubset)
        rangesubset <- utils::URLencode(rangesubset)
    }
    if (!is.null(time)) {
        validate_dimension_subset(wcs,
                                  coverage_id,
                                  type = "temporal",
                                  subset = time)
    }
    if (!is.null(elevation)) {
        validate_dimension_subset(wcs,
                                  coverage_id,
                                  type = "vertical",
                                  subset = elevation)
    }
    check_cov_contains_bbox(summary, bbox, crs)

    cli::cli_rule(left = "Downloading coverage {.val {coverage_id}}")

    coverage_id <- validate_namespace(coverage_id)

    if(length(time) > 1 | length(elevation) > 1) {

        # TODO - uncomment crs when https://github.com/eblondel/ows4R/issues/90
        # is resolved
        cov_raster <- summary$getCoverageStack(
            coverage_id,
            bbox = ows_bbox,
            #crs = crs,
            time = time,
            format = format,
            rangesubset = rangesubset,
            filename = filename
        )
        cli::cli_text()
        cli::cli_alert_success(
            "\n Coverage {.val {coverage_id}} downloaded succesfully as a
        {.pkg terra} {.cls SpatRaster} Stack"
        )
    } else {
        # TODO - uncomment crs when https://github.com/eblondel/ows4R/issues/90
        # is resolved
        cov_raster <- summary$getCoverage(
            coverage_id,
            bbox = ows_bbox,
            #crs = crs,
            time = time,
            elevation = elevation,
            format = format,
            rangesubset = rangesubset,
            filename = filename
        )
        cli::cli_text()
        cli::cli_alert_success(
            "\n Coverage {.val {coverage_id}} downloaded succesfully as a
        {.pkg terra} {.cls SpatRaster}"
        )
    }

    if (nil_values_as_na) {
        nil_value <- get_nil_value(summary)

        if (is.numeric(nil_value)) {
            cov_raster[cov_raster == nil_value] <- NA

            cli::cli_alert_info(
                "nil values {.val {nil_value}} converted to {.field NA}")
        }
    }

    return(cov_raster)
}

check_cov_contains_bbox <- function(summary, bbox, crs = NULL) {
    cov_bbox <- get_bbox(summary)

    if (!is.null(crs)){
        bbox <- sf::st_bbox(bbox,
                            crs = sf::st_crs(crs))

        if (sf::st_crs(cov_bbox) != sf::st_crs(bbox)){
            bbox <- bbox |>
                sf::st_as_sfc() |>
                sf::st_transform(crs = sf::st_crs(cov_bbox)) |>
                sf::st_bbox()
        }
    }
    test_bbox <- !c(
        bbox[c("xmax", "ymax")] <= cov_bbox[c("xmax", "ymax")],
        bbox[c("xmin", "ymin")] <= cov_bbox[c("xmax", "ymax")],
        bbox[c("xmin", "ymin")] >= cov_bbox[c("xmin", "ymin")],
        bbox[c("xmax", "ymax")] >= cov_bbox[c("xmin", "ymin")]
    )

    outlying_edges <- unique(names(test_bbox)[test_bbox])
    if (length(outlying_edges) == 0) {
        outlying_edges <- ""
    }

    if (all(test_bbox) ||
        all(outlying_edges %in% c("ymax", "ymin")) ||
        all(outlying_edges %in% c("xmax", "xmin"))
        ) {
        cli::cli_abort(
            "{.var bbox} boundaries {.val {names(test_bbox)[test_bbox]}} lie
            outside coverage extent. No overlapping data to download."
        )
    }
    if (any(test_bbox)) {
        cli::cli_warn(
            "{.var bbox} boundaries {.val {names(test_bbox)[test_bbox]}} lie
            outside coverage extent. No overlapping data to download."
        )
    }

}
