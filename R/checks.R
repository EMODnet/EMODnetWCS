
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
        rlang::warn(glue::glue('Service version {usethis::ui_value(wcs$getVersion())} ',
                               ' can result in unexpected',
                               ' behaviour on {usethis::ui_value("human activities")} server.
                            We strongly recommend reconnecting using {usethis::ui_code("service_version")} ',
                               '{usethis::ui_value("2.0.1")}'))
    } else {
        supported_versions <- wcs$getCapabilities()$
            getServiceIdentification()$
            getServiceTypeVersion()

        version <- wcs$getVersion()

        if (!checkmate::test_choice(version, supported_versions)) {
            rlang::warn(glue::glue('Service version {usethis::ui_value(version)} not',
                                   ' supported by server and can result in unexpected',
                                   ' behaviour.
                            We strongly recommend reconnecting using one of the ',
                                   'supported versions: ',
                                   '{usethis::ui_value(supported_versions)}'))
        }
    }
}

# Checks if there is internet and performs an HTTP GET request
perform_http_request <- function(service_url){
    usethis::ui_oops("WCS client creation failed.")
    usethis::ui_info("Service: {usethis::ui_value(service_url)}")

    has_internet <- function() {
        if (nzchar(Sys.getenv("NO_INTERNET_TEST_EMODNET"))) {
            return(FALSE)
        }
        curl::has_internet()
    }

    if (!has_internet()) {
        usethis::ui_info("Reason: There is no internet connection")
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
        usethis::ui_info("HTTP Status: {crayon::red(httr::http_status(request)$message)}")
        usethis::ui_line()

        is_monitor_up <- !is.null(curl::nslookup("monitor.emodnet.eu", error = FALSE))
        if (interactive() && is_monitor_up) {
            if (usethis::ui_yeah("Browse the EMODnet OGC monitor?")) {
                utils::browseURL("https://monitor.emodnet.eu/resources?lang=en&resource_type=OGC:WCS")
            }
        }

        rlang::abort("Service creation failed")

        # If no HTTP status, something else is wrong
    } else if(!httr::http_error(request)) {
        usethis::ui_info("HTTP Status: {crayon::green(httr::http_status(request)$message)}")
        usethis::ui_stop("An exception has occurred. Please raise an issue in {packageDescription('EMODnetWCS')$BugReports}")
    }

}

check_coverages <- function(wcs, coverages) {
    checkmate::assert_character(coverages)
    test_coverages <- coverages %in% get_cov_ids(wcs)

    if (!all(test_coverages)) {
        bad_coverages <- coverages[!test_coverages]
        rlang::abort(
            glue::glue("{usethis::ui_value(paste(bad_coverages, collapse = ', '))}",
                       " not valid {switch(length(bad_coverages),'1' = 'coverage', 'coverages')}",
                       " for service {usethis::ui_path(wcs$getUrl())}"))
    }
}
