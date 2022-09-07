get_service_url <- function(service) {
    emodnet_wcs()$service_url[emodnet_wcs()$service_name == service]
}

get_service_name <- function(service_url) {
    emodnet_wcs()$service_name[emodnet_wcs()$service_url == service_url]
}


get_capabilities <- function(wcs) {
    wcs$getCapabilities()
}

emdn_get_coverage_summaries <- function(wcs, coverage_ids) {
    coverage_ids |> purrr::map(~get_capabilities(wcs)$findCoverageSummaryById(.x, exact = TRUE))
}

emdn_get_coverage_summaries_all <- function(wcs) {
    get_capabilities(wcs)$getCoverageSummaries()
}
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

get_resolution <- function(summary, type = c("character", "numeric")) {
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

get_coverage_function <- function(summary, param = c("sequenceRule", "startPoint")) {
    param <- match.arg(param)
    summary$getDescription()$coverageFunction[[1]][[param]]$value
}


error_wrap <- function(expr) {

    out <- tryCatch(expr,
                    error = function(e) NA)

    if (is.null(out)) {
        cli::cli_alert_warning(
            c("Output of {.code {cli::col_cyan(rlang::enexpr(expr))}} ",
            "is {.emph {cli::col_br_magenta('NULL')}}.",
             " Returning {.emph {cli::col_br_magenta('NA')}}"))
        return(NA)
    }
    if (is.na(out)) {
        cli::cli_alert_warning(
            c("Error in {.code {cli::col_cyan(rlang::enexpr(expr))}}",
              " Returning {.emph {cli::col_br_magenta('NA')}}"))
    }

    return(out)

}

get_temporal_extent <- function(summary) {
    dim_df <- process_dimension(summary, format = "tibble")

    if (any(dim_df$type == "temporal")) {
        dim_df$range[dim_df$type == "temporal"]
    } else {
        NA
    }
}

get_vertical_extent <- function(summary) {
    dim_df <- process_dimension(summary, format = "tibble")

    if (any(dim_df$type == "vertical")) {
        dim_df$range[dim_df$type == "vertical"]
    } else {
        NA
    }
}

process_dimension <- function(x, format = c("character",
                                            "list",
                                            "tibble"),
                              include_coeffs = FALSE) {
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

validate_namespace <- function(coverage_id) {
    gsub(":", "__", coverage_id)
}

validate_bbox <- function(bbox) {
    if (is.null(bbox)) {
        return(bbox)
    } else {
        checkmate::assert_numeric(bbox,
                                  len = 4,
                                  any.missing = FALSE,
                                  names = "named")
        checkmate::assert_subset(names(bbox),
                                 choices = c(
                                     "xmin",
                                     "xmax",
                                     "ymin",
                                     "ymax"
                                 ))

        checkmate::assert_true(bbox["ymin"]  < bbox["ymax"])
        checkmate::assert_true(bbox["xmin"]  < bbox["xmax"])

        return(ows4R::OWSUtils$toBBOX(xmin = bbox["xmin"],
                                      xmax = bbox["xmax"],
                                      ymin = bbox["ymin"],
                                      ymax = bbox["ymax"]))
    }
}

validate_rangesubset <- function(summary, rangesubset) {
    cov_range_descriptions <- emdn_get_band_name(summary)
    purrr::walk(rangesubset,
                ~checkmate::assert_choice(
                    .x,
                    cov_range_descriptions,
                    .var.name = "rangesubset")
    )
}

validate_dimension_subset <- function(
        wcs,
        coverage_id,
        type = c("temporal",
                 "vertical"),
        subset) {

    type <- match.arg(type)
    coefs <- emodnet_get_coverage_dim_coefs(
        wcs,
        coverage_id,
        type)

    switch (type,
            temporal = {purrr::walk(
                subset,
                ~checkmate::assert_choice(
                    .x,
                    coefs,
                    .var.name = "time")
            )},
            vertical = {purrr::walk(
                subset,
                ~checkmate::assert_choice(
                    .x,
                    coefs,
                    .var.name = "elevation")
            )}
    )
}

has_extent_type <- function(wcs, coverage_ids,
                            type = c("temporal", "vertical",
                                     "geographic")) {
    check_coverages(wcs, coverage_ids)
    type <- match.arg(type)

    dim_dfs <- emdn_get_coverage_summaries(wcs, coverage_ids) |>
        purrr::map(~process_dimension(.x, format = "tibble"))

    dim_dfs |>
        purrr::map_lgl(~any(.x$type == type)) |>
        stats::setNames(coverage_ids)
}

get_dimension_type <- function(summary) {
    dimensions <- summary$getDimensions()

    purrr::map_chr(dimensions, ~purrr::pluck(.x, "type"))

}
