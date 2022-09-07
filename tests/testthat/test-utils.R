test_that("service urls & names crossreference correctly", {
    expect_equal(get_service_url("bathymetry"), "https://ows.emodnet-bathymetry.eu/wcs")
    expect_equal(get_service_name("https://ows.emodnet-bathymetry.eu/wcs"), "bathymetry")
})


test_that("extent & crs processed correctly", {

    summary <- create_physics_summary()[[1]]
    with_mock_dir("physics-info", {
        bbox <- emdn_get_bbox(summary)
        expect_equal(conc_bbox(bbox), "-180, -90, 180, 90")
        expect_equal(extr_bbox_crs(summary)$input, "EPSG:4326")
    })
})


test_that("dimensions processed correctly", {
    summary <- create_biology_summary()[[1]]
    with_mock_dir("biology-description",
                  {expect_equal(emdn_get_grid_size(summary), "950x400")
                      expect_equal(emdn_get_resolution(summary),
                                   "0.0422105263157895 Deg x 0.23775 Deg")
                      expect_equal(process_dimension(summary),
                                   structure("lat(deg):geographic; long(deg):geographic; time(s):temporal",
                                             class = c("glue", "character")))
                      expect_equal(emdn_get_temporal_extent(summary),
                                   "1958-02-16T00:00:00.000Z - 2016-11-16T00:00:00.000Z")
                      expect_equal(emdn_get_vertical_extent(summary), NA)
                      expect_length(process_dimension(summary, format = "list"), 3)
                  })

})

test_that("rangeType processed correctly", {
    summary <- create_biology_summary()[[1]]
    with_mock_dir("biology-description",
                  {
                      expect_equal(emdn_get_nil_value(summary), 9.96921e+36)
                      expect_equal(emdn_get_band_name(summary), "relative_abundance")
                      expect_equal(emdn_get_uom(summary), "W.m-2.Sr-1")
                      expect_equal(emdn_get_constraint(summary), "-3.4028235e+38, 3.4028235e+38")
                      expect_equal(emdn_get_coverage_function(summary), "Linear")
                      expect_equal(emdn_get_coverage_function(summary,
                                                         param = "startPoint"),
                                   "0 0")
                  })

})

test_that("error wrap works", {
    expect_equal(error_wrap(stop()), NA)
    expect_equal(error_wrap(NULL), NA)
    expect_equal(error_wrap("success"), "success")
})

test_that("validate_namespace works", {
    expect_equal(validate_namespace("emodnet:2018_st_All_avg_POSTER"),
                 "emodnet__2018_st_All_avg_POSTER")
    expect_equal(validate_namespace("emodnet__2018_st_All_avg_POSTER"),
                 "emodnet__2018_st_All_avg_POSTER")
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


