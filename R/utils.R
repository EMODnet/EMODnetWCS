get_service_url <- function(service) {
    emodnet_wcs()$service_url[emodnet_wcs()$service_name == service]
}

get_service_name <- function(service_url) {
    emodnet_wcs()$service_name[emodnet_wcs()$service_url == service_url]
}


get_capabilities <- function(wcs) {
    wcs$getCapabilities()
}

get_cov_summaries <- function(wcs, coverages) {
    coverages |> purrr::map(~wcs$getCapabilities()$findCoverageSummaryById(.x, exact = TRUE))
}

get_all_cov_summaries <- function(wcs) {
    wcs$getCapabilities()$getCoverageSummaries()
}
get_cov_ids <- function(wcs) {
    wcs$getCapabilities()$getCoverageSummaries() |>
        purrr::map_chr(~.x$getId())

}

get_bbox <- function(summary) {
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

get_WGS84bbox <- function(summary) {
    summary$getWGS84BoundingBox()$WGS84BoundingBox$getBBOX()
}

get_nil_value <- function(summary) {
    summary$getDescription()$rangeType$DataRecord$field$Quantity$nilValues$NilValues$nilValue$value
}

get_description <- function(summary) {
    summary$getDescription()$rangeType$DataRecord$field$Quantity$description$value
}

get_uom <- function(summary) {
    summary$getDescription()$rangeType$DataRecord$field$Quantity$uom$attrs$code
}

get_constraint <- function(summary) {
    summary$getDescription()$rangeType$DataRecord$field$Quantity$constraint$
        AllowedValues$interval$value |> strsplit(" ") |> unlist() |>
        as.numeric() |> paste(collapse = ", ")

}


get_grid_size <- function(summary, type = c("character", "numeric")) {
    type <- match.arg(type)

    grid_envelope <- summary$getDescription()$domainSet$limits$GridEnvelope
    low <- grid_envelope$low$value |> strsplit(" ") |> unlist() |> as.numeric()
    high <- grid_envelope$high$value |> strsplit(" ") |> unlist() |> as.numeric()
    diff <- high - low  + 1

    switch (type,
            character = paste(diff, collapse = "x"),
            numeric = diff
    )

}

get_resolution <- function(summary, type = c("character", "numeric")) {
    type <- match.arg(type)

    boundaries <- summary$getDescription()$boundedBy
    upper_crn <- boundaries$upperCorner[1,] |> unlist()
    lower_crn <- boundaries$lowerCorner[1,]  |> unlist()
    grid_size <- get_grid_size(summary, type = "numeric")
    uom <- boundaries$attrs$uomLabels

    resolution <- (upper_crn - lower_crn) / grid_size
    attr(resolution, "uom") <- uom

    switch (type,
            character = paste(paste0(resolution,
                                     unlist(strsplit(uom, " "))),
                              collapse = " x "),
            numeric = resolution
    )

}

get_coverage_function <- function(summary, param = c("sequenceRule", "startPoint")) {
    param <- match.arg(param)
    summary$getDescription()$coverageFunction[[1]][[param]]$value
}


error_wrap <- function(expr) {
    tryCatch(expr, error = function(e) NA)
}

process_dimension <- function(x, format = c("character", "list", "tibble")) {
    format <- match.arg(format)
    dimensions <- x$getDimensions()

    # internal format specific processing functions
    process_character <- function(x) {
        purrr::map_chr(x,
                        ~glue::glue('{tolower(.x[["label"]])}',
                                    '({tolower(.x[["uom"]])}):',
                                    '{tolower(.x[["type"]])}')) |>
            glue::glue_collapse("; ")
    }

    process_list <- function(x) {
        out <- purrr::map(x, ~head(.x, 3))
        stats::setNames(out, glue::glue('dim{seq_along(out)}'))
    }

    process_tibble <- function(x) {
        out <- purrr::map(x, ~head(.x, 3))
        tibble::tibble(
            dimension = seq_along(out),
            label = purrr::map_chr(out, ~purrr::pluck(.x, "label")) |>
                tolower(),
            uom = purrr::map_chr(out, ~purrr::pluck(.x, "uom")) |>
                tolower(),
            type = purrr::map_chr(out, ~purrr::pluck(.x, "type")) |>
                tolower())
    }

    switch(format,
           "character" = process_character(dimensions),
           "list" = process_list(dimensions),
           "tibble" = process_tibble(dimensions))
}

get_dimensions_names <- function(summary) {
    dimensions <- summary$getDescription()$boundedBy$attrs

    paste(
        paste0(unlist(strsplit(dimensions$axisLabels, " ")),
               " (",
               unlist(strsplit(dimensions$uomLabels, " ")),
               ")"),
        collapse = ", ")
}

get_dimensions_n <- function(summary) {
    summary$getDescription()$boundedBy$attrs$srsDimension |>
        as.integer()

}

validate_namespace <- function(coverage) {
    gsub(":", "__", coverage)
}
