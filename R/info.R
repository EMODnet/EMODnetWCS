.emdn_get_wcs_info <- function(wcs = NULL, service = NULL,
                                  service_version = c(
                                      "2.0.1", "2.1.0", "2.0.0",
                                      "1.1.1", "1.1.0"
                                  ),
                                  logger = c("NONE", "INFO", "DEBUG")) {
    if (is.null(wcs) & is.null(service)) {
        cli::cli_abort(c("x" = "Please provide a valid {.var service}
        name or {.cls WCSClient} object to {.var wcs}.
        Both cannot be {.val NULL}"))
    }

    if (is.null(wcs)) {
        wcs <- emdn_init_wcs_client(service, service_version, logger)
    }

    check_wcs(wcs)
    check_wcs_version(wcs)

    capabilities <- wcs$getCapabilities()
    service_id <- capabilities$getServiceIdentification()
    summaries <- capabilities$getCoverageSummaries()

    list(
        data_source = "emodnet_wcs",
        service_name = get_service_name(capabilities$getUrl()),
        service_url = capabilities$getUrl(),
        service_title = service_id$getTitle(),
        service_abstract = service_id$getAbstract(),
        service_access_constraits = service_id$getAccessConstraints(),
        service_fees = service_id$getFees(),
        service_type = service_id$getServiceType(),
        coverage_details =
            tibble::tibble(
                coverage_id = purrr::map_chr(summaries, ~ error_wrap(.x$getId())),
                dim_n = purrr::map_int(summaries, ~ error_wrap(length(.x$getDimensions()))),
                dim_names = purrr::map_chr(summaries, ~ error_wrap(emdn_get_dimensions_info(.x, format = "character"))),
                extent = purrr::map_chr(summaries, ~ error_wrap(emdn_get_bbox(.x) |> conc_bbox())),
                crs = purrr::map_chr(summaries, ~ error_wrap(extr_bbox_crs(.x)$input)),
                wgs84_bbox = purrr::map_chr(summaries, ~ error_wrap(emdn_get_WGS84bbox(.x) |> conc_bbox())),
                temporal_extent = purrr::map_chr(summaries, ~ error_wrap(emdn_get_temporal_extent(.x) |>
                                                                             paste(collapse = " - "))),
                vertical_extent = purrr::map_chr(summaries, ~ error_wrap(emdn_get_vertical_extent(.x) |>
                                                                             paste(collapse = " - "))),
                subtype = purrr::map_chr(summaries, ~ error_wrap(.x$CoverageSubtype))
            )
    )
}

#' Get EMODnet WCS service and available coverage information.
#'
#' @param wcs A `WCSClient` R6 object, created with function [`emdn_init_wcs_client`].
#' @inheritParams emdn_init_wcs_client
#' @importFrom rlang .data `%||%`
#' @return `emdn_get_wcs_info` & `emdn_get_wcs_info` return a list of service
#' level metadata, including a tibble containing coverage level metadata for each
#' coverage available from the service. `emdn_get_coverage_info` returns a list
#' containing a tibble of more detailed metadata for each coverage specified.
#'
#' ## `emdn_get_wcs_info` / `emdn_get_all_wcs_info`
#'
#' `emdn_get_wcs_info` and `emdn_get_all_wcs_info` return a list with the
#' following metadata:
#' - **`data_source`:** the EMODnet source of data.
#' - **`service_name`:** the EMODnet WCS service name.
#' - **`service_url`:** the EMODnet WCS service URL.
#' - **`service_title`:** the EMODnet WCS service title.
#' - **`service_abstract`:** the EMODnet WCS service abstract.
#' - **`service_access_constraits`:** any access constraints associated with the EMODnet WCS service.
#' - **`service_fees`:** any access fees associated with the EMODnet WCS service.
#' - **`service_type`:** the EMODnet WCS service type.
#' - **`coverage_details`:** a tibble of details of each coverage available through EMODnet WCS service:
#'   - **`coverage_id`:** the coverage ID.
#'   - **`dim_n`:** the number of coverage dimensions
#'   - **`dim_names`:** the coverage dimension names, units (in brackets) and types.
#'   - **`extent`:** the coverage extent (`xmin`, `ymin`, `xmax` and `ymax`).
#'   - **`crs`:** the coverage CRS (Coordinate Reference System).
#'   - **`wgs84_bbox`:** the coverage extent (`xmin`, `ymin`, `xmax` and `ymax`)
#'   in WGS84 (EPSG:4326) CRS coordinates.
#'   - **`temporal_extent`:** the coverage temporal extent (`min` - `max`), `NA` if coverage
#'   contains no temporal dimension.
#'   - **`vertical_extent`:** the coverage vertical extent (`min` - `max`), `NA` if coverage
#'   contains no vertical dimension.
#'   - **`subtype`:** the coverage subtype.
#'
#' ## `emdn_get_coverage_info`
#'
#' `emdn_get_coverage_info` returns a tibble with a row for each coverage
#' specified and columns with the following details:
#' - **`data_source`:** the EMODnet source of data.
#' - **`service_name`:** the EMODnet WCS service name.
#' - **`service_url`:** the EMODnet WCS service URL.
#' - **`coverage_ids`:** the coverage ID.
#' - **`band_description`:** the description of the data contained in the band of the coverage.
#' - **`band_uom`:** the unit of measurement of the data contained in the band of the coverage.
#' - **`constraint`:** the range of values of the data contained in the band of the coverage.
#' - **`nil_value`:** the nil value of the data contained in the band of the coverage.
#' - **`grid_size`:** the spatial size of the coverage grid (ncol x nrow).
#' - **`resolution`:** the spatial resolution (pixel size) of the coverage grid
#' in the CRS units of measurement (size in the `x` dimension x size in the `y` dimension).
#' - **`dim_n`:** the number of coverage dimensions
#' - **`dim_names`:** the coverage dimension names, units (in brackets) and types.
#' - **`extent`:** the coverage extent (`xmin`, `ymin`, `xmax` and `ymax`).
#' - **`crs`:** the coverage CRS (Coordinate Reference System).
#' - **`wgs84_bbox`:** the coverage extent (`xmin`, `ymin`, `xmax` and `ymax`)
#'   in WGS84 (EPSG:4326) CRS coordinates.
#' - **`temporal_extent`:** the coverage temporal extent (`min` - `max`), `NA` if coverage
#'   contains no temporal dimension.
#' - **`vertical_extent`:** the coverage vertical extent (`min` - `max`), `NA` if coverage
#'   contains no vertical dimension.
#' - **`subtype`:** the coverage subtype.
#' - **`fn_seq_rule`:** the function describing the sequence rule which specifies
#' the relationship between the axes of data and coordinate system axes.
#' - **`fn_start_point`:** the location of the origin of the data in the coordinate system.
#'
#' For additional details on WCS metadata, see the GDAL wiki section on
#' [WCS Basics and GDAL](https://trac.osgeo.org/gdal/wiki/WCS%2Binteroperability)
#'
#' @export
#' @describeIn emdn_get_wcs_info Get info on all coverages from am EMODnet WCS service.
#' @examples
#' # Get information from a wcs object.
#' wcs <- emdn_init_wcs_client(service = "seabed_habitats")
#' emdn_get_wcs_info(wcs)
#' # Get information using a service name.
#' emdn_get_wcs_info(service = "biology")
#' # Get detailed info for specific coverages from wcs object
#' coverage_ids <- c(
#'   "emdn_open_maplibrary__mediseh_cora",
#'   "emdn_open_maplibrary__mediseh_posidonia"
#' )
#' emdn_get_coverage_info(wcs = wcs,
#'                        coverage_ids = coverage_ids)
emdn_get_wcs_info <- memoise::memoise(.emdn_get_wcs_info)


.emdn_get_all_wcs_info <- function(logger = c("NONE", "INFO", "DEBUG")) {
    purrr::map(
        emdn_wcs()$service_name,
        ~ suppressMessages(emdn_get_wcs_info(service = .x,
                                                logger = logger))
    ) |>
        stats::setNames(emdn_wcs()$service_name)
}

#' @describeIn emdn_get_wcs_info Get metadata on all services and all available
#' coverages from each service.
#' @export
emdn_get_all_wcs_info <- memoise::memoise(.emdn_get_all_wcs_info)

.emdn_get_coverage_info <- function(wcs = NULL, service = NULL,
                                           coverage_ids,
                                           service_version = c(
                                               "2.0.1", "2.1.0", "2.0.0",
                                               "1.1.1", "1.1.0"
                                           ),
                                           logger = c("NONE", "INFO", "DEBUG")) {

    if (is.null(wcs) & is.null(service)) {
        cli::cli_abort(c("x" = "Please provide a valid {.var service}
        name or {.cls WCSClient} object to {.var wcs}.
        Both cannot be {.val NULL}"))
    }

    if (is.null(wcs)) {
        wcs <- emdn_init_wcs_client(service, service_version, logger)
    }

    check_wcs(wcs)
    check_wcs_version(wcs)
    check_coverages(wcs, coverage_ids)

    capabilities <- wcs$getCapabilities()

    summaries <- purrr::map(validate_namespace(coverage_ids),
                            ~capabilities$findCoverageSummaryById(.x)) |>
        unlist(recursive = FALSE)

    tibble::tibble(
        data_source = "emodnet_wcs",
        service_name = wcs$getUrl(),
        service_url = get_service_name(wcs$getUrl()),
        coverage_id = purrr::map_chr(summaries, ~ error_wrap(.x$getId())),
        band_description = purrr::map_chr(summaries, ~ error_wrap(emdn_get_band_name(.x))),
        band_uom = purrr::map_chr(summaries, ~ error_wrap(emdn_get_uom(.x))),
        constraint = purrr::map_chr(summaries, ~ error_wrap(emdn_get_constraint(.x) |>
                                                                paste(collapse = ", "))),
        nil_value = purrr::map_dbl(summaries, ~ error_wrap(emdn_get_nil_value(.x))),
        dim_n = purrr::map_int(summaries, ~ error_wrap(length(.x$getDimensions()))),
        dim_names = purrr::map_chr(summaries, ~ error_wrap(emdn_get_dimensions_info(.x, format = "character"))),
        grid_size = purrr::map_chr(summaries, ~ error_wrap(emdn_get_grid_size(.x) |>
                                                               paste(collapse = "x"))),
        resolution = purrr::map_chr(summaries, ~ error_wrap(emdn_get_resolution(.x) |>
                                                                conc_resolution())),
        extent = purrr::map_chr(summaries, ~ error_wrap(emdn_get_bbox(.x) |> conc_bbox())),
        crs = purrr::map_chr(summaries, ~ error_wrap(extr_bbox_crs(.x)$input)),
        wgs84_extent = purrr::map_chr(summaries, ~ error_wrap(emdn_get_WGS84bbox(.x) |> conc_bbox())),
        temporal_extent = purrr::map_chr(summaries, ~ error_wrap(emdn_get_temporal_extent(.x) |>
                                                                     paste(collapse = " - "))),
        vertical_extent = purrr::map_chr(summaries, ~ error_wrap(emdn_get_vertical_extent(.x) |>
                                                                     paste(collapse = " - "))),
        subtype = purrr::map_chr(summaries, ~ error_wrap(.x$CoverageSubtype)),
        fn_seq_rule = purrr::map_chr(summaries, ~ error_wrap(
            emdn_get_coverage_function(.x)$sequence_rule)),
        fn_start_point = purrr::map_chr(summaries,
                                        ~error_wrap(
                                            emdn_get_coverage_function(.x)$start_point |>
                                                paste(collapse = ",")))
    )
}

#' @describeIn emdn_get_wcs_info Get metadata for specific coverages. Requires a
#' `WCSClient` R6 object as input.
#' @param coverage_ids character vector of coverage IDs.
#' @inheritParams emdn_get_wcs_info
#' @importFrom memoise memoise
#' @details To minimize the number of requests sent to webservices,
#' these functions use [`memoise`](https://memoise.r-lib.org/) to cache results
#' inside the active R session.
#' To clear the cache, re-start R or run `memoise::forget(emdn_get_wcs_info)`/`memoise::forget(emdn_get_coverage_info)`
#'
#' @export
emdn_get_coverage_info <- memoise::memoise(.emdn_get_coverage_info)

#' Get temporal or vertical coefficients for a coverage
#' @param wcs A `WCSClient` R6 object, created with function [`emdn_init_wcs_client`].
#' @param coverage_id character string. Coverage ID.
#' @param type character string. The dimension type for which
#' coefficients will be returned.
#'
#' @return a vector of coefficients.
#' @export
#'
#' @examples
#' wcs <- emdn_init_wcs_client(service =  "biology")
#' emdn_get_coverage_dim_coefs(wcs,
#'                               "Emodnetbio__ratio_large_to_small_19582016_L1_err")
emdn_get_coverage_dim_coefs <- function(wcs,
                                           coverage_id,
                                           type = c("temporal",
                                                    "vertical")) {

    type <- match.arg(type)
    checkmate::assert_character(coverage_id, len = 1)
    check_extent_type <- emdn_has_extent_type(wcs,
                                         coverage_id,
                                         type)

    if (check_extent_type) {
        summary <- emdn_get_coverage_summaries(wcs, coverage_id)[[1]]
        dim_type_id <- which(emdn_get_dimension_types(summary) == type)

        coefs <- summary |>
            emdn_get_dimensions_info(
                format = "list",
                include_coeffs = TRUE) |>
            purrr::pluck(dim_type_id,
                         "coefficients") |>
            unlist()

        attr(coefs, "type") <- glue::glue(
            "{type}_coefficents"
            )

        return(coefs)

    } else {
        cli::cli_warn(
            "{.field coverage_id} {.val {coverage_id}}
            has no {.val {type}} dimension."
        )

        return(NA)
    }
}
