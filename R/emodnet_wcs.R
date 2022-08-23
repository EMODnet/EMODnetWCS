.emodnet_wcs <- function() {
    read.csv(
        system.file(
            "services.csv",
            package = "EMODnetWCS")
        ) |>
        tibble::as_tibble()
}

#' Available EMODnet Web Coverage Services
#'
#' @return Tibble of available EMODnet Web Coverage Services
#'
#' @export
emodnet_wcs <- memoise::memoise(.emodnet_wcs)
