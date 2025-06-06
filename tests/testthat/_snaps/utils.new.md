# dimensions processed correctly

    Code
      emdn_get_dimensions_info(summary, format = "tibble")
    Output
      # A tibble: 0 x 4
      # i 4 variables: dimension <int>, label <chr>, uom <chr>, type <chr>

---

    Code
      emdn_get_coverage_dim_coefs(wcs, coverage_ids = "Emodnetbio__aca_spp_19582016_L1")
    Condition
      Warning:
      coverage_id "Emodnetbio__aca_spp_19582016_L1" has no "temporal" dimension.
    Output
      $Emodnetbio__aca_spp_19582016_L1
      [1] NA
      

