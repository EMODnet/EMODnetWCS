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
    wcs <- create_biology_wcs()
    summary <- create_biology_summary()[[1]]
    with_mock_dir("biology-description",
                  {expect_equal(emdn_get_grid_size(summary),
                                c(ncol = 951, nrow = 401))
                      expect_equal(emdn_get_resolution(summary),
                                   structure(
                                       c(x = 0.1,
                                         y = 0.1),
                                       uom = c("Deg", "Deg")
                                   )
                      )
                      expect_equal(emdn_get_dimensions_info(summary),
                                   structure("lat(deg):geographic; long(deg):geographic; time(s):temporal",
                                             class = c("glue", "character")))
                      expect_equal(emdn_get_dimensions_n(summary), 3)
                      expect_equal(emdn_get_temporal_extent(summary),
                                   c("1958-02-16T00:00:00.000Z", "2016-11-16T00:00:00.000Z"))
                      expect_equal(emdn_get_dimension_types(summary),
                                   c("geographic", "geographic", "temporal"))
                      expect_equal(emdn_get_dimensions_names(summary),
                                   "Lat (Deg), Long (Deg), time (s)")
                      expect_equal(emdn_get_vertical_extent(summary), NA)
                      expect_length(emdn_get_dimensions_info(summary, format = "list"), 3)
                      expect_snapshot(emdn_get_dimensions_info(summary, format = "tibble"))
                      expect_snapshot(
                          emdn_get_coverage_dim_coefs(
                              wcs,
                              coverage_ids = "Emodnetbio__aca_spp_19582016_L1")
                      )


                  })

})

test_that("rangeType processed correctly", {
    summary <- create_biology_summary()[[1]]
    with_mock_dir("biology-description",
                  {
                      expect_equal(emdn_get_nil_value(summary), 9.96921e+36)
                      expect_equal(emdn_get_band_name(summary), structure("relative_abundance",
                                                                          uom = "W.m-2.Sr-1"))
                      expect_equal(emdn_get_uom(summary), c(relative_abundance = "W.m-2.Sr-1"))
                      expect_equal(emdn_get_constraint(summary),
                                   list(
                                       relative_abundance = c(-3.4028235e+38,
                                                              3.4028235e+38)))
                      expect_equal(emdn_get_coverage_function(summary),
                                   list(sequence_rule = "Linear",
                                        start_point = c(0, 0),
                                        axis_order = c("+2", "+1")))
                  })

    summary <- create_physics_summary()[[1]]
    with_mock_dir("physics-info", {
        expect_equal(emdn_get_band_name(summary),
                     structure(
                         c("RED_BAND",
                           "GREEN_BAND",
                           "BLUE_BAND"),
                         uom = c("W.m-2.Sr-1",
                                 "W.m-2.Sr-1",
                                 "W.m-2.Sr-1")
                     )
        )
        expect_equal(emdn_get_uom(summary),
                     c(RED_BAND = "W.m-2.Sr-1",
                       GREEN_BAND = "W.m-2.Sr-1",
                       BLUE_BAND = "W.m-2.Sr-1"
                     )
        )
        expect_equal(emdn_get_constraint(summary),
                     list(RED_BAND = c(0, 255),
                          GREEN_BAND = c(0, 255),
                          BLUE_BAND = c(0, 255)))
    })
})
