library(httptest)

with_mock_dir <- function(name, ...) {
  httptest::with_mock_dir(file.path("../fixtures", name), ...)
}

create_biology_wcs <- function() {
  with_mock_dir("wcs-biology", {
    emdn_init_wcs_client(service = "biology")
  })
}

create_human_activities_wcs <- function() {
  with_mock_dir("wcs-human-activities", {
    emdn_init_wcs_client(service = "human_activities")
  })
}

create_seabed_wcs <- function() {
  with_mock_dir("wcs-seabed", {
    emdn_init_wcs_client(service = "seabed_habitats")
  })
}

create_biology_summary <- function() {
  with_mock_dir("wcs-biology-summary", {
    emdn_init_wcs_client(service = "biology") %>%
      emdn_get_coverage_summaries(
        coverage_ids = "Emodnetbio__aca_spp_19582016_L1"
      )
  })
}
