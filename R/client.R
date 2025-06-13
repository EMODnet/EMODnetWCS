#' Initialise an EMODnet WCS client
#'
#' @param service the EMODnet OGC WCS service name.
#' For available services, see [`emdn_wcs()`].
#' @param service_version the WCS service version. Defaults to "2.0.1".
#' @param logger character string. Level of logger: 'NONE' for no logger, 'INFO'
#'  to get ows4R logs, 'DEBUG' for all internal logs (such as as Curl details)
#'
#' @return An [`ows4R::WCSClient`] R6 object with methods for interfacing an OGC
#' Web Coverage Service.
#' @import ows4R
#' @export
#'
#' @seealso `WCSClient` in package `ows4R`.
#' @examplesIf interactive()
#' wcs <- emdn_init_wcs_client(service = "bathymetry")
emdn_init_wcs_client <- function(
  service,
  service_version = c(
    "2.0.1",
    "2.1.0",
    "2.0.0",
    "1.1.1",
    "1.1.0"
  ),
  logger = c("NONE", "INFO", "DEBUG")
) {
  check_service_name(service)
  service_version <- match.arg(service_version)
  logger <- match.arg(logger)
  if (logger == "NONE") {
    logger <- NULL
  }
  service_url <- get_service_url(service)

  create_client <- function() {
    config <- httr::config()

    wcs <- suppressWarnings(ows4R::WCSClient$new(
      service_url,
      serviceVersion = service_version,
      headers = c(
        "User-Agent" = "emodnet.wcs R package https://github.com/EMODnet/emodnet.wcs"
      ),
      config = config,
      logger = logger
    ))

    check_wcs(wcs)

    cli::cli_alert_success("WCS client created succesfully")
    cli::cli_alert_info("Service: {.url {wcs$getUrl()}}")
    cli::cli_alert_info("Service: {.val {wcs$getVersion()}}")

    check_wcs_version(wcs)

    wcs
  }

  tryCatch(
    create_client(),
    error = function(e) {
      check_service(perform_http_request(service_url))
    }
  )
}
