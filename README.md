
<!-- README.md is generated from README.Rmd. Please edit that file -->

# EMODnetWCS

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![CRAN
status](https://www.r-pkg.org/badges/version/EMODnetWCS)](https://CRAN.R-project.org/package=EMODnetWCS)
<!-- badges: end -->

The goal of EMODnetWCS is to allow interrogation of and access to
EMODnet geographic raster data in R though the [EMODnet Web Coverage
Services](https://github.com/EMODnet/Web-Service-Documentation#web-coverage-service-wcs).
[Web Coverage services (WCS)](https://www.ogc.org/standards/wcs) offer
multi-dimensional coverage data for access over the Internet. This
package was developed by Sheffield University as part of EMODnet Biology
WP4.

## Installation

You can install the development version of EMODnetWCS from GitHub with:

``` r
# install.packages("remotes")
remotes::install_github("EMODnet/EMODnetWCS")
```

## Available services

All available services are contained in the tibble returned by
`emodnet_wcs()`.

| service_name     | service_url                                                                   |
|:-----------------|:------------------------------------------------------------------------------|
| bathymetry       | <https://ows.emodnet-bathymetry.eu/wcs>                                       |
| biology          | <https://geo.vliz.be/geoserver/Emodnetbio/wcs>                                |
| human_activities | <https://ows.emodnet-humanactivities.eu/wcs>                                  |
| physics          | <https://geoserver.emodnet-physics.eu/geoserver/wcs>                          |
| seabed_habitats  | <https://ows.emodnet-seabedhabitats.eu/geoserver/emodnet_open_maplibrary/wcs> |

To explore available services in Rstudio use:

``` r
View(emodnet_wcs())
```

## Create Service Client

Create new WCS Client. Specify the service using the `service` argument.

``` r
wcs_bio <- emodnet_init_wcs_client(service = "biology")
#> Loading ISO 19139 XML schemas...
#> Loading ISO 19115 codelists...
#> Loading IANA mime types...
#> No encoding supplied: defaulting to UTF-8.
#> ✔ WCS client created succesfully
#> ℹ Service: 'https://geo.vliz.be/geoserver/Emodnetbio/wcs'
#> ℹ Version: '2.1.0'

wcs_bio$getUrl()
#> [1] "https://geo.vliz.be/geoserver/Emodnetbio/wcs"
```
