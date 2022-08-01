library(httptest)

with_mock_dir <- function(name, ...) {
    httptest::with_mock_dir(testthat::test_path(file.path("fixtures", name)), ...)
}

create_biology_wcs <- function() {
    with_mock_dir("wcs-biology", {
        emodnet_init_wcs_client(service = "biology")
    })
}
