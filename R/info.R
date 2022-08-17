.emodnet_get_wcs_info <- function(wcs = NULL, service = NULL,
                                  service_version = c(
                                      "2.0.1", "2.1.0", "2.0.0",
                                      "1.1.1", "1.1.0"
                                  ),
                                  logger = c("NONE", "INFO", "DEBUG")) {
    if (is.null(wcs) & is.null(service)) {
        usethis::ui_stop("Please provide a valid {usethis::ui_field('service')} name or {usethis::ui_field('wcs')} object.
                         Both cannot be {usethis::ui_value('NULL')}")
    }

    if (is.null(wcs)) {
        wcs <- emodnet_init_wcs_client(service, service_version, logger)
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
                name = error_wrap(purrr::map_chr(summaries, ~ .x$getId())),
                dimension_n = error_wrap(purrr::map_int(summaries, ~ length(.x$getDimensions()))),
                dimension_names = error_wrap(purrr::map_chr(summaries, ~ process_dimension(.x, format = "character"))),
                extent = error_wrap(purrr::map_chr(summaries, ~ get_bbox(.x) |> conc_bbox())),
                crs = error_wrap(purrr::map_chr(summaries, ~ extr_bbox_crs(.x))),
                wgs84_bbox = error_wrap(purrr::map_chr(summaries, ~ get_WGS84bbox(.x) |> conc_bbox())),
                subtype = error_wrap(purrr::map_chr(summaries, ~ .x$CoverageSubtype))
            )
    )
}

#' Get WCS available coverage information
#'
#' @param wcs A `WCSClient` R6 object with methods for interfacing an OGC Web Feature Service.
#' @inheritParams emodnet_init_wcs_client
#' @importFrom rlang .data `%||%`
#' @return `emodnet_get_wcs_info` & `emodnet_get_wcs_info` return a list of service
#' level metadata, including a tibble containing coverage level metadata for each
#' coverage available from the service. `emodnet_get_wcs_coverage_info` returns a list
#' containing a tibble of more detailed metadata for each coverage specified. See
#' **Details** for more information.
#' @export
#' @describeIn emodnet_get_wcs_info Get info on all coverages from am EMODnet WCS service.
#' @examples
#' emodnet_get_wcs_info(service = "biology")
#' # Query a wcs object
#' wcs <- emodnet_init_wcs_client(service = "seabed_habitats")
#' emodnet_get_wcs_info(wcs)
#' # Get detailed info for specific coverages from wcs object
#' coverages <- c(
#'   "emodnet_open_maplibrary__mediseh_cora",
#'   "emodnet_open_maplibrary__mediseh_posidonia"
#' )
#' emodnet_get_wcs_coverage_info(wcs = wcs, coverages = coverages)
emodnet_get_wcs_info <- memoise::memoise(.emodnet_get_wcs_info)


.emodnet_get_all_wcs_info <- function(logger = c("NONE", "INFO", "DEBUG")) {
    purrr::map(
        emodnet_wcs()$service_name,
        ~ suppressMessages(emodnet_get_wcs_info(service = .x,
                                                logger = logger))
    ) |>
        stats::setNames(emodnet_wcs()$service_name)
}

#' @describeIn emodnet_get_wcs_info Get metadata on all services and all available
#' coverages from each service.
#' @export
emodnet_get_all_wcs_info <- memoise::memoise(.emodnet_get_all_wcs_info)

.emodnet_get_wcs_coverage_info <- function(wcs = NULL, service = NULL,
                                           coverages,
                                           service_version = c(
                                               "2.0.1", "2.1.0", "2.0.0",
                                               "1.1.1", "1.1.0"
                                           ),
                                           logger = c("NONE", "INFO", "DEBUG")) {

    if (is.null(wcs) & is.null(service)) {
        usethis::ui_stop("Please provide a valid {usethis::ui_field('service')} name or {usethis::ui_field('wcs')} object.
                         Both cannot be {usethis::ui_value('NULL')}")
    }

    if (is.null(wcs)) {
        wcs <- emodnet_init_wcs_client(service, service_version, logger)
    }

    check_wcs(wcs)
    check_wcs_version(wcs)

    capabilities <- wcs$getCapabilities()

    summaries <- purrr::map(validate_namespace(coverages),
                            ~capabilities$findCoverageSummaryById(.x)) |>
        unlist(recursive = FALSE)

    tibble::tibble(
        data_source = "emodnet_wcs",
        service_name = wcs$getUrl(),
        service_url = get_service_name(wcs$getUrl()),
        band_name = error_wrap(purrr::map_chr(summaries, ~ .x$getId())),
        description = error_wrap(purrr::map_chr(summaries, ~ get_description(.x))),
        band_uom = error_wrap(purrr::map_chr(summaries, ~ get_uom(.x))),
        constraint = error_wrap(purrr::map_chr(summaries, ~ get_constraint(.x))),
        nil_value = error_wrap(purrr::map_chr(summaries, ~ get_nil_value(.x))),
        grid_size = error_wrap(purrr::map_chr(summaries, ~ get_grid_size(.x))),
        resolution = error_wrap(purrr::map_chr(summaries, ~ get_resolution(.x))),
        dim_n = error_wrap(purrr::map_int(summaries, ~ get_dimensions_n(.x))),
        dim_names = error_wrap(purrr::map_chr(summaries, ~ get_dimensions_names(.x))),
        extent = error_wrap(purrr::map_chr(summaries, ~ get_bbox(.x) |> conc_bbox())),
        crs = error_wrap(purrr::map_chr(summaries, ~ extr_bbox_crs(.x)$input)),
        wgs84_extent = error_wrap(purrr::map_chr(summaries, ~ get_WGS84bbox(.x) |> conc_bbox())),
        subtype = error_wrap(purrr::map_chr(summaries, ~ .x$CoverageSubtype)),
        fn_seq_rule = purrr::map_chr(summaries, ~ get_coverage_function(.x)),
        fn_start_point = purrr::map_chr(summaries,
                                        ~get_coverage_function(.x,
                                                               param = "startPoint"))
    )
}

#' @describeIn emodnet_get_wcs_info Get metadata for specific coverages. Requires a
#' `wcs` object as input.
#' @param coverages character vector of coverage IDs.
#' @inheritParams emodnet_get_wcs_info
#' @importFrom memoise memoise
#' @details To minimize the number of requests sent to webservices,
#' these functions use `memoise` to cache results inside the active R session.
#' To clear the cache, re-start R or run `memoise::forget(emodnet_get_wcs_info)`/`memoise::forget(emodnet_get_wcs_coverage_info)`.
#' @export
emodnet_get_wcs_coverage_info <- memoise::memoise(.emodnet_get_wcs_coverage_info)

