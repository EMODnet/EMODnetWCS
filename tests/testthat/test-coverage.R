test_that("coverages downloaded correctly", {
    wcs <- create_biology_wcs()
    coverage_id <- "Emodnetbio__cal_fin_19582016_L1_err"
    bbox <- c(xmin = 0,
              ymin = 40,
              xmax = 2,
              ymax = 42)
    with_mock_dir("biology-coverage",
                  {
                      cov_raster <- emodnet_get_wcs_coverage(
                          wcs,
                          coverage_id = coverage_id,
                          bbox = bbox,
                          time = c( "1963-11-16T00:00:00.000Z",
                                    "1964-02-16T00:00:00.000Z"),
                          rangesubset = "Relative error"
                      )

                      expect_snapshot_output(
                          cov_raster
                      )
                  })
    with_mock_dir("biology-coverage",
                  {bbox <- c(xmin = 0,
                             ymin = 80,
                             xmax = 5,
                             ymax = 85)
                  expect_snapshot_error(
                      emodnet_get_wcs_coverage(
                          wcs,
                          coverage_id = coverage_id,
                          bbox = bbox,
                      )
                  )
                  expect_snapshot_error(
                      emodnet_get_wcs_coverage(
                          wcs,
                          coverage_id = coverage_id,
                          time = "randomtime",
                      )
                  )
                  })
})