
test_that("get wcs info works", {
    wcs <- create_physics_wcs()
    with_mock_dir("physics-info", {
        expect_snapshot_value(emodnet_get_wcs_info(wcs),
                              style = "deparse")
    })
})

test_that("get wcs coverage info works", {
    wcs <- create_physics_wcs()
    with_mock_dir("physics-info", {
        expect_snapshot_value(
            emodnet_get_wcs_coverage_info(wcs,
                                          coverages = "emodnet__EP_GEO_NER_OTHR_NN_NN_RAS"),
            style = "deparse")
    })
})