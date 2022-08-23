test_that("service urls & names crossreference correctly", {
    expect_equal(get_service_url("bathymetry"), "https://ows.emodnet-bathymetry.eu/wcs")
    expect_equal(get_service_name("https://ows.emodnet-bathymetry.eu/wcs"), "bathymetry")
})


test_that("extent & crs processed correctly", {

    summary <- create_physics_summary()[[1]]
    with_mock_dir("physics-description", {
        bbox <- get_bbox(summary)
        expect_equal(conc_bbox(bbox), "-180, -90, 180, 90")
        expect_equal(extr_bbox_crs(summary)$input, "EPSG:4326")
    })
})


test_that("dimensions processed correctly", {
    summary <- create_biology_summary()[[1]]
    with_mock_dir("biology-description",
                  {expect_equal(get_grid_size(summary), "950x400")
                      expect_equal(get_resolution(summary),
                                   "0.0422105263157895 Deg x 0.23775 Deg")
                      expect_equal(process_dimension(summary),
                                   structure("lat(deg):geographic; long(deg):geographic; time(s):temporal",
                                             class = c("glue", "character")))
                      expect_equal(get_temporal_extent(summary),
                                   "1958-02-16T00:00:00.000Z - 2016-11-16T00:00:00.000Z")
                      expect_equal(get_vertical_extent(summary), NA)
                  })

})

test_that("rangeType processed correctly", {
    summary <- create_biology_summary()[[1]]
    with_mock_dir("biology-description",
                  {
                      expect_equal(get_nil_value(summary), 9.96921e+36)
                      expect_equal(get_description(summary), "relative_abundance")
                      expect_equal(get_uom(summary), "W.m-2.Sr-1")
                      expect_equal(get_constraint(summary), "-3.4028235e+38, 3.4028235e+38")
                      expect_equal(get_coverage_function(summary), "Linear")
                      expect_equal(get_coverage_function(summary,
                                                         param = "startPoint"),
                                   "0 0")
                  })

})
