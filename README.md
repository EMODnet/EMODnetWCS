
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
See below for available Services. This package was developed by
Sheffield University as part of EMODnet Biology WP4.

[Web Coverage services (WCS)](https://www.ogc.org/standards/wcs) is a
standard created by the OGC that refers to the receiving of geospatial
information as ‘coverages’: digital geospatial information representing
space-varying phenomena. One can think of it as Web Feature Service
(WFS) for raster data. It gets the ‘source code’ of the map, but in this
case its not raw vectors but raw imagery.

An important distinction must be made between WCS and Web Map Service
(WMS). They are similar, and can return similar formats, but a WCS is
able to return more information, including valuable metadata and more
formats. It additionally allows more precise queries, potentially
against multi-dimensional backend formats.

## Installation

You can install the development version of EMODnetWCS from GitHub with:

``` r
# install.packages("remotes")
remotes::install_github("EMODnet/EMODnetWCS")
```

Load the library

``` r
library(EMODnetWCS)
library(ows4R)
#> Loading required package: geometa
#> Loading ISO 19139 XML schemas...
#> Loading ISO 19115 codelists...
#> Loading IANA mime types...
#> No encoding supplied: defaulting to UTF-8.
#> Loading required package: keyring
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
wcs <- emodnet_init_wcs_client(service = "biology")
#> ✔ WCS client created succesfully
#> ℹ Service: 'https://geo.vliz.be/geoserver/Emodnetbio/wcs'
#> ℹ Version: '2.0.1'

wcs$getUrl()
#> [1] "https://geo.vliz.be/geoserver/Emodnetbio/wcs"
```

## Get Information about a WCS service

Get information about a WCS service by supplying a `wcs` object to
`emodnet_get_wcs_info`

``` r
emodnet_get_wcs_info(wcs)
#> Loading required package: sf
#> Linking to GEOS 3.9.1, GDAL 3.4.0, PROJ 8.1.1; sf_use_s2() is TRUE
#> $data_source
#> [1] "emodnet_wcs"
#> 
#> $service_name
#> [1] "biology"
#> 
#> $service_url
#> [1] "https://geo.vliz.be/geoserver/Emodnetbio/wcs"
#> 
#> $service_title
#> [1] "EMODnet Biology"
#> 
#> $service_abstract
#> [1] "The EMODnet Biology products include a set of gridded map layers showing the average abundance of marine species for different time windows (seasonal, annual) using geospatial modelling. The spatial modelling tool used to calculate the gridded abundance maps is based on DIVA. DIVA (Data-Interpolating Variational Analysis) is a tool to create gridded data sets from discrete point measurements of the ocean. For the representation of time dynamics, it was decided to produce gridded maps for sliding time windows, e.g. combining one or more years  in one gridded map, so that relatively smooth animated GIF presentations can be produced that show the essential change over time. EMODnet Biology’s data products include the Operational Ocean Products and Services (OOPS), harvested by ICES."
#> 
#> $service_access_constraits
#> [1] "NONE"
#> 
#> $service_fees
#> [1] "NONE"
#> 
#> $service_type
#> [1] "urn:ogc:service:wcs"
#> 
#> $coverage_details
#> # A tibble: 10 × 7
#>    name                               dim_n dim_n…¹ extent crs   wgs84…² subtype
#>    <chr>                              <int> <chr>   <chr>  <chr> <chr>   <chr>  
#>  1 Emodnetbio__ratio_large_to_small_…     3 dim1=l… 34.95… EPSG… -75.05… Rectif…
#>  2 Emodnetbio__aca_spp_19582016_L1        3 dim1=l… 34.95… EPSG… -75.05… Rectif…
#>  3 Emodnetbio__cal_fin_19582016_L1_e…     3 dim1=l… 34.95… EPSG… -75.05… Rectif…
#>  4 Emodnetbio__cal_hel_19582016_L1_e…     3 dim1=l… 34.95… EPSG… -75.05… Rectif…
#>  5 Emodnetbio__met_luc_19582016_L1_e…     3 dim1=l… 34.95… EPSG… -75.05… Rectif…
#>  6 Emodnetbio__oit_spp_19582016_L1_e…     3 dim1=l… 34.95… EPSG… -75.05… Rectif…
#>  7 Emodnetbio__tem_lon_19582016_L1_e…     3 dim1=l… 34.95… EPSG… -75.05… Rectif…
#>  8 Emodnetbio__chli_19582016_L1_err       3 dim1=l… 34.95… EPSG… -75.05… Rectif…
#>  9 Emodnetbio__tot_lar_19582016_L1_e…     3 dim1=l… 34.95… EPSG… -75.05… Rectif…
#> 10 Emodnetbio__tot_sma_19582016_L1_e…     3 dim1=l… 34.95… EPSG… -75.05… Rectif…
#> # … with abbreviated variable names ¹​dim_names, ²​wgs84_bbox
```

Info can also be extracted using a service name instead of a `wcs`
object.

``` r
emodnet_get_wcs_info(service = "bathymetry")
#> ✔ WCS client created succesfully
#> ℹ Service: 'https://ows.emodnet-bathymetry.eu/wcs'
#> ℹ Version: '2.0.1'
#> $data_source
#> [1] "emodnet_wcs"
#> 
#> $service_name
#> [1] "bathymetry"
#> 
#> $service_url
#> [1] "https://ows.emodnet-bathymetry.eu/wcs"
#> 
#> $service_title
#> [1] "EMODnet Bathymetry WCS"
#> 
#> $service_abstract
#> [1] ""
#> 
#> $service_access_constraits
#> [1] "NONE"
#> 
#> $service_fees
#> [1] "NONE"
#> 
#> $service_type
#> [1] "urn:ogc:service:wcs"
#> 
#> $coverage_details
#> # A tibble: 6 × 7
#>   name                        dim_n dim_names       extent crs   wgs84…¹ subtype
#>   <chr>                       <int> <chr>           <chr>  <chr> <chr>   <chr>  
#> 1 emodnet__mean                   2 dim1=lat(deg):… 15, -… EPSG… -36, 1… Rectif…
#> 2 emodnet__mean_2016              2 dim1=lat(deg):… 25, -… EPSG… -36, 2… Rectif…
#> 3 emodnet__mean_2018              2 dim1=lat(deg):… 15, -… EPSG… -36, 1… Rectif…
#> 4 emodnet__mean_atlas_land        2 dim1=lat(deg):… 15, -… EPSG… -36, 1… Rectif…
#> 5 emodnet__mean_multicolour       2 dim1=lat(deg):… 15, -… EPSG… -36, 1… Rectif…
#> 6 emodnet__mean_rainbowcolour     2 dim1=lat(deg):… 15, -… EPSG… -36, 1… Rectif…
#> # … with abbreviated variable name ¹​wgs84_bbox
```

``` r
emodnet_get_wcs_coverage_info(service = "human_activities", 
                              coverages = "emodnet:2017_01_st_00")
#> ✔ WCS client created succesfully
#> ℹ Service: 'https://ows.emodnet-humanactivities.eu/wcs'
#> ℹ Version: '2.0.1'
#> # A tibble: 1 × 18
#>   data_s…¹ servi…² servi…³ name  band_…⁴ band_…⁵ const…⁶ nil_v…⁷ grid_…⁸ resol…⁹
#>   <chr>    <chr>   <chr>   <chr> <chr>   <chr>   <chr>   <chr>   <chr>   <chr>  
#> 1 emodnet… https:… human_… emod… GRAY_I… W.m-2.… -3.402… -9999.0 7508x6… 1000m …
#> # … with 8 more variables: dim_n <int>, dim_names <chr>, extent <chr>,
#> #   crs <chr>, wgs84_extent <chr>, subtype <chr>, fn_seq_rule <chr>,
#> #   fn_start_point <chr>, and abbreviated variable names ¹​data_source,
#> #   ²​service_name, ³​service_url, ⁴​band_description, ⁵​band_uom, ⁶​constraint,
#> #   ⁷​nil_value, ⁸​grid_size, ⁹​resolution
#> # ℹ Use `colnames()` to see all variable names
```

> **Note**
>
> To minimize the number of requests sent to webservices, these
> functions use [`memoise`](https://memoise.r-lib.org/) to cache results
> inside the active R session. To clear the cache, re-start R or run
> `memoise::forget(emodnet_get_wcs_info)`/`memoise::forget(emodnet_get_wcs_coverage_info)`
