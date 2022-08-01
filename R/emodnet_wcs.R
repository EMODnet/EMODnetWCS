.emodnet_wcs <- function() {
    readr::read_csv(
        system.file("services.csv", package = "EMODnetWCS"),
        col_types = readr::cols(
            service_name = readr::col_character(),
            service_url = readr::col_character()
        )
    )
}

#' Available EMODnet Web Coverage Services
#'
#' @return Tibble of available EMODnet Web Coverage Services
#'
#' @export
emodnet_wcs <- memoise::memoise(.emodnet_wcs)
