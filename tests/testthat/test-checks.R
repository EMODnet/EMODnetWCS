test_that("validate_namespace works", {
  expect_equal(
    validate_namespace("emodnet:2018_st_All_avg_POSTER"),
    "emodnet__2018_st_All_avg_POSTER"
  )
  expect_equal(
    validate_namespace("emodnet__2018_st_All_avg_POSTER"),
    "emodnet__2018_st_All_avg_POSTER"
  )
})

test_that("validate_bbox works", {
  expect_equal(
    validate_bbox(c(
      xmin = -180,
      ymin = -90.000000000036,
      xmax = 180.000000000072,
      ymax = 90
    )),
    structure(c(
      -180, -90.000000000036,
      180.000000000072, 90
    ),
    .Dim = c(2L, 2L),
    .Dimnames = list(
      c("x", "y"),
      c("min", "max")
    )
    )
  )
  expect_error(validate_bbox(c(
    xmin = -90.000000000036,
    ymin = -180,
    xmax = -180.000000000072,
    ymax = 90
  )))
  expect_error(validate_bbox(c(
    xmin = -90.000000000036,
    ymin = -180,
    ymax = 90
  )))
  expect_error(validate_bbox(c(
    xmin = -180,
    ymin = -90.000000000036,
    xmax = 180.000000000072,
    ymax = "90"
  )))
  expect_error(validate_bbox(NA))
  expect_equal(validate_bbox(NULL), NULL)
})

test_that("check bbox works", {
  expect_equal(error_wrap(stop()), NA)
  expect_equal(error_wrap(NULL), NA)
  expect_equal(error_wrap("success"), "success")
})


test_that("error wrap works", {
  expect_equal(error_wrap(stop()), NA)
  expect_equal(error_wrap(NULL), NA)
  expect_equal(error_wrap("success"), "success")
})


test_that("check coverages works", {
  wcs <- create_biology_wcs()
  coverage_ids <- c(
    "Emodnetbio__ratio_large_to_small_19582016_L1_err",
    "Emodnetbio__aca_spp_19582016_L1",
    "Emodnetbio__cal_fin_19582016_L1_err",
    "Emodnetbio__cal_hel_19582016_L1_err"
  )
  expect_invisible(check_coverages(wcs, coverage_ids))
  expect_error(check_coverages(wcs, "erroneous_id"))
})
