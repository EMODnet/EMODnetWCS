## code to prepare `emodnet_wcs` dataset goes here
library(dplyr)

# Use the commented code below to create a tibble from a tribble of copied data
# after you have copied the services table from EMODnet WCS documentation:
# (https://github.com/EMODnet/Web-Service-Documentation#web-coverage-service-wcs)
#
# datapasta::tribble_paste()

emodnet_wcs <- tibble::tribble(
    ~Portal,                                ~Description,                                                                                                           ~WCS.GetCapabilities,
    "Bathymetry",                             "Data Products",                                      "https://ows.emodnet-bathymetry.eu/wcs?SERVICE=WCS&REQUEST=GetCapabilities&VERSION=2.0.1",
    "Biology",                             "Data Products",                               "https://geo.vliz.be/geoserver/Emodnetbio/wcs?SERVICE=WCS&REQUEST=GetCapabilities&VERSION=2.0.1",
    "Human Activities",                    "Data and Data Products",                                 "https://ows.emodnet-humanactivities.eu/wcs?SERVICE=WCS&REQUEST=GetCapabilities&VERSION=2.0.1",
    "Physics",                                 "Platforms",                          "https://geoserver.emodnet-physics.eu/geoserver/wcs?SERVICE=WCS&REQUEST=GetCapabilities&VERSION=2.0.1",
    "Seabed Habitats", "Individual habitat map and model datasets", "https://ows.emodnet-seabedhabitats.eu/geoserver/emodnet_open_maplibrary/wcs?SERVICE=WCS&REQUEST=GetCapabilities&VERSION=2.0.1"
)

# process table
emodnet_wcs <- emodnet_wcs |>
    rename( service_name = "Portal",
            service_url = "WCS.GetCapabilities") |>
    select(-Description) |>
    mutate(service_url = stringr::str_remove(service_url, "\\?SERVICE=WCS&REQUEST.*$"),
           service_name = janitor::make_clean_names(service_name))

# write as csv to /inst directory
readr::write_csv(emodnet_wcs, here::here("inst", "services.csv"))
