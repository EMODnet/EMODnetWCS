#' @importFrom utils read.csv
.emdn_wcs <- function() {
  utils::read.csv(
    system.file(
      "services.csv",
      package = "EMODnetWCS"
    )
  ) %>%
    tibble::as_tibble()
}

#' Available EMODnet Web Coverage Services
#'
#' @return Tibble of available EMODnet Web Coverage Services
#' @examples
#' emdn_wcs()
#'
#' @export
emdn_wcs <- memoise::memoise(.emdn_wcs)
