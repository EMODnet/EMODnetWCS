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
    summary$getBoundingBox()$BoundingBox$getBBOX()
}

conc_bbox <- function(bbox) {
    paste(round(bbox, 2), collapse = ", ")
}

extr_bbox_crs <- function(summary) {
    summary$getBoundingBox()$BoundingBox$attrs$crs
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
    summary$getDescription()$rangeType$DataRecord$field$Quantity$constraint$AllowedValues$interval$value
}

error_wrap <- function(expr) {
    tryCatch(expr, error = function(e) NA)
}

process_dimension <- function(x, format = c("character", "list", "tibble")) {
    format <- match.arg(format)
    dimensions <- x$getDimensions()


    # internal format specific processing functions
    process_character <- function(x) {
        purrr::imap_chr(x,
                        ~glue::glue('dim{.y}={tolower(.x[["label"]])}',
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
