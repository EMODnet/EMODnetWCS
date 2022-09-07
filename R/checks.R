# ---- checks ----
check_service_name <- function(service) {
    checkmate::assert_choice(service, emodnet_wcs()$service_name)
}

check_wcs <- function(wcs) {
    checkmate::assertR6(
        wcs,
        classes = c("WCSClient", "OWSClient", "OGCAbstractObject", "R6")
    )
}

check_wcs_version <- function(wcs) {
    if (get_service_name(wcs$getUrl()) == "human_activities" &&
        wcs$getVersion() != "2.0.1") {

        cli::cli_warn(c("!" = 'Service version {.val {wcs$getVersion()}}
                        can result in unexpected  behaviour on the
                        {.val human activities} server.
                            We strongly recommend reconnecting using {.var service_version}
                      {.val 2.0.1}.'))
    } else {
        supported_versions <- wcs$getCapabilities()$
            getServiceIdentification()$
            getServiceTypeVersion()

        version <- wcs$getVersion()

        if (!checkmate::test_choice(version, supported_versions)) {
            cli::cli_warn(c("!" = 'Service version {.val {version}} not  supported by server
                            and can result in unexpected behaviour.',
                            'We strongly recommend reconnecting using one of the
                            supported versions: ',
                            '{.val {supported_versions}}'))
        }
    }
}

# Checks if there is internet and performs an HTTP GET request
perform_http_request <- function(service_url){
    cli::cli_alert_danger("WCS client creation failed.")
    cli::cli_alert_warning("Service: {.val {service_url}}")

    has_internet <- function() {
        if (nzchar(Sys.getenv("NO_INTERNET_TEST_EMODNET"))) {
            return(FALSE)
        }
        curl::has_internet()
    }

    if (!has_internet()) {
        cli::cli_alert_info("Reason: There is no internet connection")
        return(NULL)
    }

    service_url |>
        paste0("?request=GetCapabilities") |>
        httr::GET()

}

# Checks if there is internet connection and HTTP status of the service
check_service <- function(request) {

    if (is.null(request)) {
        rlang::abort("WCS client creation failed.")
    }

    if (httr::http_error(request)) {
        cli::cli_alert_info("HTTP Status: {cli::col_red(httr::http_status(request)$message)}")
        cli::cli_text("")

        is_monitor_up <- !is.null(curl::nslookup("monitor.emodnet.eu", error = FALSE))
        if (interactive() && is_monitor_up) {
            cli::cli_ul(c(
                "Browse the EMODnet OGC monitor for more info on
                the status of the services by visiting
                {.url https://monitor.emodnet.eu/resources?lang=en&resource_type=OGC:WCS}"))
        }

        rlang::abort("Service creation failed")

        # If no HTTP status, something else is wrong
    } else if(!httr::http_error(request)) {
        cli::cli_alert_info("HTTP Status: {cli::col_green(httr::http_status(request)$message)}")
        cli::cli_abort(
        c("x" = "An exception has occurred. Please raise an
          issue in {.url {packageDescription('EMODnetWCS')$BugReports}}"))
    }

}

check_coverages <- function(wcs, coverages) {
    checkmate::assert_character(coverages)
    test_coverages <- coverages %in% emdn_get_coverage_ids(wcs)

    if (!all(test_coverages)) {
        bad_coverages <- coverages[!test_coverages]
        cli::cli_abort(c("x" = "{.val {bad_coverages}} not valid coverage{?s}
                         for service {.url {wcs$getUrl()}}"))
    }
}

# ---- validations ----
validate_namespace <- function(coverage_id) {
    gsub(":", "__", coverage_id)
}

validate_bbox <- function(bbox) {
    if (is.null(bbox)) {
        return(bbox)
    } else {
        checkmate::assert_numeric(bbox,
                                  len = 4,
                                  any.missing = FALSE,
                                  names = "named")
        checkmate::assert_subset(names(bbox),
                                 choices = c(
                                     "xmin",
                                     "xmax",
                                     "ymin",
                                     "ymax"
                                 ))

        checkmate::assert_true(bbox["ymin"]  < bbox["ymax"])
        checkmate::assert_true(bbox["xmin"]  < bbox["xmax"])

        return(ows4R::OWSUtils$toBBOX(xmin = bbox["xmin"],
                                      xmax = bbox["xmax"],
                                      ymin = bbox["ymin"],
                                      ymax = bbox["ymax"]))
    }
}

validate_rangesubset <- function(summary, rangesubset) {
    cov_range_descriptions <- emdn_get_band_name(summary)
    purrr::walk(rangesubset,
                ~checkmate::assert_choice(
                    .x,
                    cov_range_descriptions,
                    .var.name = "rangesubset")
    )
}

validate_dimension_subset <- function(
        wcs,
        coverage_id,
        type = c("temporal",
                 "vertical"),
        subset) {

    type <- match.arg(type)
    coefs <- emodnet_get_coverage_dim_coefs(
        wcs,
        coverage_id,
        type)

    switch (type,
            temporal = {purrr::walk(
                subset,
                ~checkmate::assert_choice(
                    .x,
                    coefs,
                    .var.name = "time")
            )},
            vertical = {purrr::walk(
                subset,
                ~checkmate::assert_choice(
                    .x,
                    coefs,
                    .var.name = "elevation")
            )}
    )
}

# ---- error-handling ----
error_wrap <- function(expr) {

    out <- tryCatch(expr,
                    error = function(e) NA)

    if (is.null(out)) {
        cli::cli_alert_warning(
            c("Output of {.code {cli::col_cyan(rlang::enexpr(expr))}} ",
              "is {.emph {cli::col_br_magenta('NULL')}}.",
              " Returning {.emph {cli::col_br_magenta('NA')}}"))
        return(NA)
    }
    if (is.na(out)) {
        cli::cli_alert_warning(
            c("Error in {.code {cli::col_cyan(rlang::enexpr(expr))}}",
              " Returning {.emph {cli::col_br_magenta('NA')}}"))
    }

    return(out)

}
