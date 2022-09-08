# get wcs info works

    list(data_source = "emodnet_wcs", service_name = "physics", service_url = "https://geoserver.emodnet-physics.eu/geoserver/wcs", 
        service_title = "Web Coverage Service", service_abstract = "This server implements the WCS specification 1.0 and 1.1.1, it's reference implementation of WCS 1.1.1. All layers published by this service are available on WMS also.\n     ", 
        service_access_constraits = "NONE", service_fees = "NONE", 
        service_type = "urn:ogc:service:wcs", coverage_details = structure(list(
            coverage_id = "emodnet__EP_GEO_NER_OTHR_NN_NN_RAS", dim_n = 2L, 
            dim_names = "lat(deg):geographic; long(deg):geographic", 
            extent = "-180, -90, 180, 90", crs = "EPSG:4326", wgs84_bbox = "-180, -90, 180, 90", 
            temporal_extent = "NA", vertical_extent = "NA", subtype = "RectifiedGridCoverage"), class = c("tbl_df", 
        "tbl", "data.frame"), row.names = c(NA, -1L)))

# get wcs coverage info works

    structure(list(data_source = "emodnet_wcs", service_name = "https://geoserver.emodnet-physics.eu/geoserver/wcs", 
        service_url = "physics", coverage_id = "emodnet__EP_GEO_NER_OTHR_NN_NN_RAS", 
        band_description = "BLUE_BAND", band_uom = "W.m-2.Sr-1", 
        constraint = "0, 255", nil_value = NA_real_, dim_n = 2L, 
        dim_names = "lat(deg):geographic; long(deg):geographic", 
        grid_size = "21601x10801", resolution = "0.0166658950974525 Deg x 0.01666512359967 Deg", 
        extent = "-180, -90, 180, 90", crs = "EPSG:4326", wgs84_extent = "-180, -90, 180, 90", 
        temporal_extent = "NA", vertical_extent = "NA", subtype = "RectifiedGridCoverage", 
        fn_seq_rule = "Linear", fn_start_point = "0,0"), class = c("tbl_df", 
    "tbl", "data.frame"), row.names = c(NA, -1L))

