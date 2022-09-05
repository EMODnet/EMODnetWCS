
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
    test_coverages <- coverages %in% get_cov_ids(wcs)

    if (!all(test_coverages)) {
        bad_coverages <- coverages[!test_coverages]
        cli::cli_abort(c("x" = "{.val {bad_coverages}} not valid coverage{?s}
                         for service {.url {wcs$getUrl()}}"))
    }
}
