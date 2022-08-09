.emodnet_get_wcs_coverage_info <- function(wcs, coverages) {

    check_wcs(wcs)
    capabilities <- wcs$getCapabilities()

    wcs_coverages <- purrr::map(coverages, capabilities$findFeatureTypeByName) %>%
        unlist(recursive = FALSE)

    tibble::tibble(
        data_source = "emodnet_wcs",
        service_name = wcs$getUrl(),
        service_url = get_service_name(wcs$getUrl()),
        coverage_name = purrr::map_chr(wcs_coverages, ~.x$getId()),
        title = purrr::map_chr(wcs_coverages, ~.x$getTitle()),
        abstract = purrr::map_chr(wcs_coverages, ~getAbstractNull(.x)),
        class = purrr::map_chr(wcs_coverages, ~.x$getClassName()),
        format = "sf"
    )
}

#' @describeIn emodnet_get_wcs_info Get metadata for specific coverages. Requires a
#' `wcs` object as input.
#' @inheritParams emodnet_get_wcs_coverages
#' @importFrom memoise memoise
#' @details To minimize the number of requests sent to webservices,
#' these functions use `memoise` to cache results inside the active R session.
#' To clear the cache, re-start R or run `memoise::forget(emodnet_get_wcs_info)`/`memoise::forget(emodnet_get_wcs_coverage_info)`.
#' @export
emodnet_get_wcs_coverage_info <- memoise::memoise(.emodnet_get_wcs_coverage_info)

.emodnet_get_wcs_info <- function(wcs = NULL, service = NULL,
                                  service_version = c("2.0.1", "2.1.0", "2.0.0",
                                                      "1.1.1", "1.1.0",
                                                      "1.0.0"),
                                  logger = c("NONE", "INFO", "DEBUG")) {

    if(is.null(wcs) & is.null(service)){
        usethis::ui_stop("Please provide a valid {usethis::ui_field('service')} name or {usethis::ui_field('wcs')} object.
                         Both cannot be {usethis::ui_value('NULL')}")
    }

    if(is.null(wcs)){
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
        coverage_name = error_wrap(purrr::map_chr(summaries, ~.x$getId())),
        coverage_dimensions = error_wrap(purrr::map_int(summaries, ~length(.x$getDimensions()))),
        coverage_dim_meta = error_wrap(purrr::map_chr(summaries, ~process_dimension(.x, format = "character"))),
        coverage_bbox = error_wrap(purrr::map_chr(summaries, ~get_bbox(.x) |> conc_bbox())),
        coverage_crs = error_wrap(purrr::map_chr(summaries, ~extr_bbox_crs(.x))),
        coverage_wgs84_bbox = error_wrap(purrr::map_chr(summaries, ~get_WGS84bbox(.x) |> conc_bbox())),
        coverage_subtype = error_wrap(purrr::map_chr(summaries, ~.x$CoverageSubtype))
    ))

}
#' Get WCS available coverage information
#'
#' @param wcs A `WCSClient` R6 object with methods for interfacing an OGC Web Feature Service.
#' @inheritParams emodnet_init_wcs_client
#' @importFrom rlang .data `%||%`
#' @return a tibble containg metadata on each coverage available from the service.
#' @export
#' @describeIn emodnet_get_wcs_info Get info on all coverages from am EMODnet WCS service.
#' @examples
#' emodnet_get_wcs_info(service = "bathymetry")
#' # Query a wcs object
#' wcs <- emodnet_init_wcs_client(service = "seabed_habitats")
#' emodnet_get_wcs_info(wcs)
#' # Get detailed info for specific coverages from wcs object
#' coverages <- c("emodnet_open_maplibrary__mediseh_cora",
#'            "emodnet_open_maplibrary__mediseh_posidonia")
#' emodnet_get_wcs_coverage_info(wcs = wcs, coverages = coverages)
emodnet_get_wcs_info <- memoise::memoise(.emodnet_get_wcs_info)


.emodnet_get_all_wcs_info <- function(logger = c("NONE", "INFO", "DEBUG")) {
    purrr::map(emodnet_wcs()$service_name,
               ~suppressMessages(emodnet_get_wcs_info(service = .x, logger = logger))) |>
        stats::setNames(emodnet_wcs()$service_name)
}

#' @describeIn emodnet_get_wcs_info Get metadata on all coverages and all available
#' services from server.
#' @export
emodnet_get_all_wcs_info <- memoise::memoise(.emodnet_get_all_wcs_info)









