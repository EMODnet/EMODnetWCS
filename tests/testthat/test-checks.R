test_that("validate_namespace works", {
    expect_equal(validate_namespace("emodnet:2018_st_All_avg_POSTER"),
                 "emdn__2018_st_All_avg_POSTER")
    expect_equal(validate_namespace("emdn__2018_st_All_avg_POSTER"),
                 "emdn__2018_st_All_avg_POSTER")
})

test_that("validate_bbox works", {
    expect_equal(validate_bbox(c(xmin = -180,
                                 ymin = -90.000000000036,
                                 xmax = 180.000000000072,
                                 ymax = 90)),
                 structure(c(-180, -90.000000000036,
                             180.000000000072, 90),
                           .Dim = c(2L, 2L),
                           .Dimnames = list(c("x", "y"),
                                            c("min", "max")))
    )
    expect_error(validate_bbox(c(xmin = -90.000000000036,
                                 ymin = -180,
                                 xmax = -180.000000000072,
                                 ymax = 90)))
    expect_error(validate_bbox(c(xmin = -90.000000000036,
                                 ymin = -180,
                                 ymax = 90)))
    expect_error(validate_bbox(c(xmin = -180,
                                 ymin = -90.000000000036,
                                 xmax = 180.000000000072,
                                 ymax = "90")))
    expect_error(validate_bbox(NA))
    expect_equal(validate_bbox(NULL), NULL)

})

test_that("error wrap works", {
    expect_equal(error_wrap(stop()), NA)
    expect_equal(error_wrap(NULL), NA)
    expect_equal(error_wrap("success"), "success")
})

