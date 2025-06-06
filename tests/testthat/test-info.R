test_that("get wcs info works", {
  wcs <- create_seabed_wcs()
  with_mock_dir("seabed-info", {
    info <- emdn_get_wcs_info(wcs)
  })
  expect_type(info, "list")
  expect_setequal(
    names(info),
    c(
      "data_source",
      "service_name",
      "service_url",
      "service_title",
      "service_abstract",
      "service_access_constraits",
      "service_fees",
      "service_type",
      "coverage_details"
    )
  )
  expect_s3_class(info[["coverage_details"]], "tbl_df")
  expect_setequal(
    names(info[["coverage_details"]]),
    c(
      "coverage_id",
      "dim_n",
      "dim_names",
      "extent",
      "crs",
      "wgs84_bbox",
      "temporal_extent",
      "vertical_extent",
      "subtype"
    )
  )
})

test_that("get wcs coverage info works", {
  wcs <- create_seabed_wcs()
  with_mock_dir("seabed-info", {
    expect_snapshot_value(
      emdn_get_coverage_info(
        wcs,
        coverage_ids = "emodnet_open_maplibrary__PT005008"
      ),
      style = "deparse"
    )
  })
})
