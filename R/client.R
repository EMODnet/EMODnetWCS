#' Initialise an EMODnet WCS client
#'
#' @param service the EMODnet OGC WCS service name.
#' For available services, see [`emodnet_wcs()`].
#' @param service_version the WCS service version. Defaults to "2.0.0".
#'
#' @return An [`ows4R::WCSClient`] R6 object with methods for interfacing an OGC Web Feature Service.
#' @export
#'
#' @seealso `WCSClient` in package `ows4R`.
#' @examples
#' \dontrun{
#' wcs <- emodnet_init_wcs_client(service = "bathymetry")
#' }
emodnet_init_wcs_client <- function(service, service_version = c("2.1.0", "2.0.1", "1.1.1", "1.1.0", "1.0")) {

    check_service_name(service)
    service_version <- match.arg(service_version)

    service_url <- get_service_url(service)

    create_client <- function(){

        config <- httr::config()
        # TODO: remove this when the geology web services are fixed
        # is_linux <- (Sys.info()[["sysname"]] == "Linux")
        # is_geology <- (grepl("^geology_", service))
        # config <- if (is_linux && is_geology) {
        #     httr::config(ssl_cipher_list = 'DEFAULT@SECLEVEL=1')
        # } else {
        #     httr::config()
        # }

        wcs <- suppressWarnings(ows4R::WCSClient$new(
            service_url,
            serviceVersion = service_version,
            headers = c("User-Agent" = "EMODnetWCS R package https://github.com/EMODnet/EMODnetWCS"),
            config = config
        ))

        check_wcs(wcs)
        usethis::ui_done("WCS client created succesfully")
        usethis::ui_info("Service: {usethis::ui_value(wcs$getUrl())}")
        usethis::ui_info("Version: {usethis::ui_value(wcs$getVersion())}")

        wcs
    }

    tryCatch(
        create_client(),
        error = function(e) {check_service(perform_http_request(service_url))}
    )

}

check_service_name <- function(service) {
    checkmate::assert_choice(service, emodnet_wcs()$service_name)
}

check_wcs <- function(wcs) {
    checkmate::assertR6(
        wcs,
        classes = c("WCSClient", "OWSClient", "OGCAbstractObject", "R6")
    )
}

get_service_url <- function(service) {
    emodnet_wcs()$service_url[emodnet_wcs()$service_name == service]
}

get_service_name <- function(service_url) {
    emodnet_wcs()$service_name[emodnet_wcs()$service_url == service_url]
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
        usethis::ui_stop("An exception has occurred. Please raise an issue in {packageDescription('EMODnetWFS')$BugReports}")
    }

}


