test_that("Default connection works", {
  wcs <- create_biology_wcs()
  expect_equal(class(wcs), c("WCSClient", "OWSClient", "OGCAbstractObject", "R6"))
  expect_equal(wcs$getUrl(), "https://geo.vliz.be/geoserver/Emodnetbio/wcs")
})

test_that("Error when wrong service", {
  expect_snapshot(emdn_init_wcs_client("blop"), error = TRUE)
})


test_that("Error when wrong service version", {
  expect_snapshot(emdn_init_wcs_client(
    service = "human_activities",
    service_version = "2.2.2"
  ), error = TRUE)
})

test_that("Warning when unsupported service version", {
  skip_if_offline()
  expect_snapshot(emdn_init_wcs_client(
    service = "human_activities",
    service_version = "1.1.1"
  ))
})

test_that("Services down handled", {
  webmockr::httr_mock()

  test_url <- "https://demo.geo-solutions.it/geoserver/ows?request=GetCapabilities"

  webmockr::stub_request("get", uri = test_url) %>%
    webmockr::wi_th(headers = list("Accept" = "application/json, text/xml, application/xml, */*")) %>%
    webmockr::to_return(status = 500) %>%
    webmockr::to_return(status = 200)

  req_fail <- httr::GET(test_url)
  expect_true(httr::http_error(req_fail))

  req_success <- httr::GET(test_url)
  expect_false(httr::http_error(req_success))

  # Test check_service behavior
  expect_snapshot(check_service(req_fail), error = TRUE)
  expect_snapshot(check_service(req_success), error = TRUE)

  webmockr::disable()
})

test_that("No internet challenge", {
  withr::local_envvar(list(NO_INTERNET_TEST_EMODNET = "bla"))

  test_url <- "https://demo.geo-solutions.it/geoserver/ows?"

  expect_snapshot(
      (req_no_internet <- perform_http_request(test_url))
  )
  expect_snapshot(check_service(req_no_internet), error = TRUE)
})
