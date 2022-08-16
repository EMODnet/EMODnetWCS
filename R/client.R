#' Initialise an EMODnet WCS client
#'
#' @param service the EMODnet OGC WCS service name.
#' For available services, see [`emodnet_wcs()`].
#' @param service_version the WCS service version. Defaults to "2.0.1".
#' @param logger character string. Level of logger: 'NONE' for no logger, 'INFO' to get ows4R logs, 'DEBUG' for all internal logs (such as as Curl details)
#'
#' @return An [`ows4R::WCSClient`] R6 object with methods for interfacing an OGC Web Feature Service.
#' @export
#'
#' @seealso `WCSClient` in package `ows4R`.
#' @examples
#' \dontrun{
#' wcs <- emodnet_init_wcs_client(service = "bathymetry")
#' }
emodnet_init_wcs_client <- function(service, service_version = c("2.0.1", "2.1.0", "2.0.0",
                                                                 "1.1.1", "1.1.0"),
                                    logger = c("NONE", "INFO", "DEBUG")) {

    check_service_name(service)
    service_version <- match.arg(service_version)
    logger <- match.arg(logger)
    if (logger == "NONE") logger <- NULL
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
            config = config,
            logger = logger
        ))

        check_wcs(wcs)

        usethis::ui_done("WCS client created succesfully")
        usethis::ui_info("Service: {usethis::ui_value(wcs$getUrl())}")
        usethis::ui_info("Version: {usethis::ui_value(wcs$getVersion())}")

        check_wcs_version(wcs)

        wcs
    }

    tryCatch(
        create_client(),
        error = function(e) {check_service(perform_http_request(service_url))}
    )

}


