#' Get metadata from a `WCSClient` object.
#'
#' @inheritParams emdn_get_wcs_coverage_info
#' @return
#'  - `emdn_get_coverage_summaries`: returns a list of objects of class
#'  `<WCSCoverageSummary>` for each `coverage_id` provided.
#'  - `emdn_get_coverage_summaries_all`: returns a list of objects of class
#'  `<WCSCoverageSummary>` for each coverage avalable through the service.
#'  - `emdn_get_coverage_ids` returns a character vector of coverage ids.
#' @describeIn emdn_get_coverage_summaries Get summaries for specific coverages.
#' @export
#'
#' @examples
#' wcs <- emdn_init_wcs_client(service = "biology")
#' emdn_get_coverage_summaries_all(wcs)
#' cov_ids <- emdn_get_coverage_ids(wcs)
#' emdn_get_coverage_summaries(wcs, cov_ids[1:2])
emdn_get_coverage_summaries <- function(wcs, coverage_ids) {
    coverage_ids |> purrr::map(~get_capabilities(wcs)$findCoverageSummaryById(.x, exact = TRUE))
}

#' @describeIn emdn_get_coverage_summaries Get summaries for all available
#' coverages from a service.
#' @export
emdn_get_coverage_summaries_all <- function(wcs) {
    get_capabilities(wcs)$getCoverageSummaries()
}

#' @describeIn emdn_get_coverage_summaries Get coverage IDs for all available
#' coverages from a service.
#' @export
emdn_get_coverage_ids <- function(wcs) {
    emdn_get_coverage_summaries_all(wcs) |>
        purrr::map_chr(~.x$getId())

}

emdn_get_bbox <- function(summary) {
    #summary$getBoundingBox()$BoundingBox$getBBOX()
    boundaries <- summary$getDescription()$boundedBy
    upper <- unlist(c(boundaries$upperCorner))
    lower <- unlist(c(boundaries$lowerCorner))

    sf::st_bbox(c(xmin = lower[2],
                  xmax = upper[2],
                  ymin = lower[1],
                  ymax = upper[1]),
                crs = extr_bbox_crs(summary))
}

conc_bbox <- function(bbox) {
    paste(round(bbox, 2), collapse = ", ")
}

extr_bbox_crs <- function(summary) {

    bbox_crs <- summary$getBoundingBox()$BoundingBox$attrs$crs

    if(!is.null(bbox_crs)){
        crs_parts <- unlist(strsplit(bbox_crs, "EPSG:"))
        if(length(crs_parts)==2){
            srid <- as.integer(crs_parts[2])
            if(!is.na(srid)) bbox_crs <- sf::st_crs(srid)
        } else {
            bbox_crs <- sf::st_crs(4326)
        }
    } else {
        bbox_crs <- sf::st_crs(4326)
    }
    return(bbox_crs)
}

emdn_get_WGS84bbox <- function(summary) {
    summary$getWGS84BoundingBox()$WGS84BoundingBox$getBBOX()
}

emdn_get_nil_value <- function(summary) {
    nil_value <- summary$getDescription()$rangeType$DataRecord$field$Quantity$nilValues$NilValues$nilValue$value
    if (typeof(nil_value) == "character") {
        as.numeric(nil_value)
    } else {
        nil_value
    }
}

emdn_get_band_name <- function(summary) {
    summary$getDescription()$rangeType$DataRecord$field$Quantity$description$value
}

emdn_get_uom <- function(summary) {
    summary$getDescription()$rangeType$DataRecord$field$Quantity$uom$attrs$code
}

emdn_get_constraint <- function(summary) {
    summary$getDescription()$rangeType$DataRecord$field$Quantity$constraint$
        AllowedValues$interval$value |> strsplit(" ") |> unlist() |>
        as.numeric() |> paste(collapse = ", ")

}


emdn_get_grid_size <- function(summary, type = c("character", "numeric")) {
    type <- match.arg(type)

    grid_envelope <- summary$getDescription()$domainSet$limits
    low <- grid_envelope$low$value |> strsplit(" ") |> unlist() |> as.numeric()
    high <- grid_envelope$high$value |> strsplit(" ") |> unlist() |> as.numeric()
    diff <- high - low  + 1

    switch (type,
            character = paste(diff, collapse = "x"),
            numeric = diff
    )

}

emdn_get_resolution <- function(summary, type = c("character", "numeric")) {
    type <- match.arg(type)

    boundaries <- summary$getDescription()$boundedBy
    upper_crn <- boundaries$upperCorner[1,] |> unlist()
    lower_crn <- boundaries$lowerCorner[1,]  |> unlist()
    grid_size <- emdn_get_grid_size(summary, type = "numeric")
    uom <- unlist(strsplit(boundaries$attrs$uomLabels, " "))[1:2]

    resolution <- (upper_crn - lower_crn) / grid_size
    attr(resolution, "uom") <- uom

    switch (type,
            character = paste(paste(resolution, uom),
                              collapse = " x "),
            numeric = resolution
    )

}

emdn_get_coverage_function <- function(summary, param = c("sequenceRule", "startPoint")) {
    param <- match.arg(param)
    summary$getDescription()$coverageFunction[[1]][[param]]$value
}

emdn_get_temporal_extent <- function(summary) {
    dim_df <- emdn_get_dimensions_info(summary, format = "tibble")

    if (any(dim_df$type == "temporal")) {
        dim_df$range[dim_df$type == "temporal"]
    } else {
        NA
    }
}

emdn_get_vertical_extent <- function(summary) {
    dim_df <- emdn_get_dimensions_info(summary, format = "tibble")

    if (any(dim_df$type == "vertical")) {
        dim_df$range[dim_df$type == "vertical"]
    } else {
        NA
    }
}

emdn_get_dimensions_info <- function(summary, format = c("character",
                                            "list",
                                            "tibble"),
                              include_coeffs = FALSE) {
    format <- match.arg(format)
    dimensions <- summary$getDimensions()

    # internal format specific processing functions
    process_character <- function(x) {
        purrr::map_chr(x,
                       ~glue::glue('{tolower(.x[["label"]])}',
                                   '({tolower(.x[["uom"]])}):',
                                   '{tolower(.x[["type"]])}')) |>
            glue::glue_collapse("; ")
    }

    process_list <- function(x, include_coeffs = FALSE) {
        if (include_coeffs) {
            out <- x
        } else {
            out <- purrr::map(x, ~head(.x, 3))
        }

        stats::setNames(out, glue::glue('dim_{seq_along(out)}'))
    }

    process_tibble <- function(x) {

        tibble::tibble(
            dimension = seq_along(x),
            label = purrr::map_chr(x, ~purrr::pluck(.x, "label")) |>
                tolower(),
            uom = purrr::map_chr(x, ~purrr::pluck(.x, "uom")) |>
                tolower(),
            type = purrr::map_chr(x, ~purrr::pluck(.x, "type")) |>
                tolower(),
            range = purrr::map(x, ~purrr::pluck(.x, "coefficients") |>
                                   unlist()) |>
                purrr::map_if(function(x){!is.null(x)},
                              ~range(.x) |>
                                  paste(collapse = " - ")) |>
                purrr::map_if(is.null, function(x){NA}) |>
                unlist()
        )
    }

    switch(format,
           "character" = process_character(dimensions),
           "list" = process_list(dimensions,
                                 include_coeffs = include_coeffs),
           "tibble" = process_tibble(dimensions))
}

emdn_get_dimensions_names <- function(summary) {
    dimensions <- summary$getDescription()$boundedBy$attrs

    paste(
        paste0(unlist(strsplit(dimensions$axisLabels, " ")),
               " (",
               unlist(strsplit(dimensions$uomLabels, " ")),
               ")"),
        collapse = ", ")
}

emdn_get_dimensions_n <- function(summary) {
    summary$getDescription()$boundedBy$attrs$srsDimension |>
        as.integer()

}



emdn_has_extent_type <- function(wcs, coverage_ids,
                            type = c("temporal", "vertical",
                                     "geographic")) {
    check_coverages(wcs, coverage_ids)
    type <- match.arg(type)

    dim_dfs <- emdn_get_coverage_summaries(wcs, coverage_ids) |>
        purrr::map(~emdn_get_dimensions_info(.x, format = "tibble"))

    dim_dfs |>
        purrr::map_lgl(~any(.x$type == type)) |>
        stats::setNames(coverage_ids)
}

emdn_get_dimension_types <- function(summary) {
    dimensions <- summary$getDimensions()

    purrr::map_chr(dimensions, ~purrr::pluck(.x, "type"))

}

get_service_url <- function(service) {
    emdn_wcs()$service_url[emdn_wcs()$service_name == service]
}

get_service_name <- function(service_url) {
    emdn_wcs()$service_name[emdn_wcs()$service_url == service_url]
}


get_capabilities <- function(wcs) {
    wcs$getCapabilities()
}
