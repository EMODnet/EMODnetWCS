# ---- wcs utils ----

#' Get metadata objects from a `WCSClient` object.
#'
#' Get metadata objects from a `WCSClient` object. `<WCSCoverageSummary>`
#' in particular can be used to extract further metadata about individual
#' coverages.
#'
#' @inheritParams emdn_get_coverage_info
#' @param type a coverage dimension type. One of `"temporal"` or `"vertical"`.
#' @return
#'  - `emdn_get_coverage_summaries`: returns a list of objects of class
#'  `<WCSCoverageSummary>` for each `coverage_id` provided.
#'  - `emdn_get_coverage_summaries_all`: returns a list of objects of class
#'  `<WCSCoverageSummary>` for each coverage avalable through the service.
#'  - `emdn_get_coverage_ids` returns a character vector of coverage ids.
#'  - `emdn_get_coverage_dim_coefs` returns a list containing a vector of
#'  coefficients for each coverage requested.
#' @describeIn emdn_get_coverage_summaries Get summaries for specific coverages.
#' @export
#'
#' @examples
#' \dontrun{
#' wcs <- emdn_init_wcs_client(service = "biology")
#' cov_ids <- emdn_get_coverage_ids(wcs)
#' cov_ids
#' emdn_has_dimension(wcs,
#'   cov_ids,
#'   type = "temporal"
#' )
#' emdn_has_dimension(wcs,
#'   cov_ids,
#'   type = "vertical"
#' )
#' emdn_get_coverage_summaries(wcs, cov_ids[1:2])
#' emdn_get_coverage_summaries_all(wcs)
#' emdn_get_coverage_dim_coefs(wcs,
#'   cov_ids[1:2],
#'   type = "temporal"
#' )
#' }
emdn_get_coverage_summaries <- function(wcs, coverage_ids) {
  check_coverages(wcs, coverage_ids)
  coverage_ids %>%
    purrr::map(
      ~ get_capabilities(wcs)$findCoverageSummaryById(.x, exact = TRUE)
    )
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
  emdn_get_coverage_summaries_all(wcs) %>%
    purrr::map_chr(~ .x$getId())
}

#' @describeIn emdn_get_coverage_summaries check whether a coverage has a
#' temporal or vertical dimension.
#' @export
emdn_has_dimension <- function(
  wcs,
  coverage_ids,
  type = c("temporal", "vertical")
) {
  check_coverages(wcs, coverage_ids)
  type <- match.arg(type)

  dim_dfs <- emdn_get_coverage_summaries(wcs, coverage_ids) %>%
    purrr::map(~ emdn_get_dimensions_info(.x, format = "tibble"))

  dim_dfs %>%
    purrr::map_lgl(~ any(.x$type == type)) %>%
    stats::setNames(coverage_ids)
}

#' @return a list containing a vector of coefficients for each coverage
#' requested.
#' @describeIn emdn_get_coverage_summaries Get temporal or
#' vertical coefficients for a coverage.
#' @export
emdn_get_coverage_dim_coefs <- function(
  wcs,
  coverage_ids,
  type = c(
    "temporal",
    "vertical"
  )
) {
  type <- match.arg(type)
  check_coverages(wcs, coverage_ids)

  get_cov_coefs <- function(coverage_id, wcs, type) {
    check_extent_type <- emdn_has_dimension(
      wcs,
      coverage_id,
      type
    )
    if (check_extent_type) {
      summary <- emdn_get_coverage_summaries(
        wcs,
        coverage_id
      )[[1]]
      dim_type_id <- which(
        emdn_get_dimension_types(summary) == type
      )

      coefs <- summary %>%
        emdn_get_dimensions_info(
          format = "list",
          include_coeffs = TRUE
        ) %>%
        purrr::pluck(
          dim_type_id,
          "coefficients"
        ) %>%
        unlist()

      attr(coefs, "type") <- glue::glue(
        "{type}_coefficents"
      )

      return(coefs)
    } else {
      cli::cli_warn(
        "{.field coverage_id} {.val {coverage_id}}
            has no {.val {type}} dimension."
      )

      return(NA)
    }
  }

  purrr::map(
    coverage_ids,
    ~ get_cov_coefs(.x, wcs = wcs, type = type)
  ) %>%
    stats::setNames(coverage_ids)
}

# ---- summary utils ----

#' Get coverage metadata from a `<WCSCoverageSummary>` object.
#'
#' @param summary a `<WCSCoverageSummary>` object.
#' @param format character string. Coverage dimension info output format.
#' One of `"character"` (default), `"list"` or `"tibble"`.
#' @param include_coeffs whether to include a vector of temporal or vertical
#' dimension coefficients (if applicable) in the coverage dimension info
#' `"list"` output format. Defaults to `FALSE`. Ignored for other formats.
#'
#' @return
#' - `emdn_get_bbox`: an object of class `bbox` of length 4 expressing the
#' boundaries coverage extent/envelope. See [`sf::st_bbox()`] for more details.
#' - `emdn_get_WGS84bbox`: an object of class `bbox` of length 4 expressing the
#' boundaries coverage extent/envelope. See [`sf::st_bbox()`] for more details.
#' - `emdn_get_band_nil_values` a numeric scalar of the value representing nil values
#' in a coverage.
#' - `emdn_get_band_descriptions` a character vector of band descriptions.
#' - `emdn_get_band_uom` a character vector of band units of measurement.
#' - `emdn_get_band_constraints` a list of numeric vectors of length 2 indicating the min and max
#' values of the data contained in each bands of the coverage.
#' - `emdn_get_grid_size` a numeric vector of length 2 giving the spatial size in
#' grid cells (pixels) of the coverage grid (ncol x nrow)
#' - `emdn_get_resolution` a numeric vector of length 2 giving the spatial resolution
#' of grid cells (size in the `x` dimension, size in the `y` dimension) of a coverage. The attached attribute `uom` gives the units of
#' measurement of each dimension.
#' - `emdn_get_coverage_function` a list with elements:
#'   - `sequence_rule`, character string, the function describing the sequence
#'   rule, i.e. the relationship between the axes of data and coordinate system
#'   axes.
#'   - `starting_point` a numeric vector of length 2, the location of the origin
#'   of the data in the coordinate system.
#'   - `axis_order` a character vector of length 2 specifying the axis order and
#'   direction of mapping of values onto the grid, beginning at the starting point. For
#'   example, `"+2 +1"` indicates the value range is ordered from the bottom
#'   left to the top right of the grid envelope - lowest to highest in the x-axis
#'   direction first (`+2`), then lowest to highest in the y-axis direction (`+1`)
#'   from the `starting_point`.
#' - `emdn_get_temporal_extent` if the coverage has a temporal dimension, a numeric
#' vector of length 2 giving the min and max values of the dimension.
#' Otherwise, NA.
#' - `emdn_get_vertical_extent` if the coverage has a vertical dimension, a numeric
#' vector of length 2 giving the min and max values of the dimension.
#' Otherwise, NA.
#' - `emdn_get_dimensions_info` output depends on `format` argument:
#'   - `character`: (default) a concatenated character string of dimension
#'   information
#'   - `list`: a list of dimension information
#'   - `tibble`: a tibble of dimension information
#' @examples
#' wcs <- emdn_init_wcs_client(service = "biology")
#' summaries <- emdn_get_coverage_summaries_all(wcs)
#' summary <- summaries[[1]]
#' # get bbox
#' emdn_get_bbox(summary)
#' # get WGS84 bbox
#' emdn_get_WGS84bbox(summary)
#' # get the nil value of a coverage
#' emdn_get_band_nil_values(summary)
#' # get coverage band descriptions
#' emdn_get_band_descriptions(summary)
#' # get band units of measurement
#' emdn_get_band_uom(summary)
#' # get range of band values
#' emdn_get_band_constraints(summary)
#' # get coverage grid size
#' emdn_get_grid_size(summary)
#' # get coverage resolution
#' emdn_get_resolution(summary)
#' # get coverage grid function
#' emdn_get_coverage_function(summary)
#' # get the extent of the temporal dimension
#' emdn_get_temporal_extent(summary)
#' # get the extent of the vertical dimension
#' emdn_get_vertical_extent(summary)
#' # get information about coverage dimensions in various formats
#' emdn_get_dimensions_info(summary)
#' emdn_get_dimensions_info(summary, format = "list")
#' emdn_get_dimensions_info(summary, format = "tibble")
#' # get dimension names
#' emdn_get_dimensions_names(summary)
#' # get number of dimensions
#' emdn_get_dimensions_n(summary)
#' # get dimensions types
#' emdn_get_dimension_types(summary)
#' @describeIn emdn_get_bbox Get the bounding box (geographic extent) of a
#' coverage. Coordinates are given in the same Coordinate Reference System
#' as the coverage.
#' @export
emdn_get_bbox <- function(summary) {
  # summary$getBoundingBox()$BoundingBox$getBBOX()
  boundaries <- summary$getDescription()$boundedBy
  upper <- unlist(c(boundaries$upperCorner))
  lower <- unlist(c(boundaries$lowerCorner))

  sf::st_bbox(
    c(
      xmin = lower[2],
      xmax = upper[2],
      ymin = lower[1],
      ymax = upper[1]
    ),
    crs = extr_bbox_crs(summary)
  )
}

#' @describeIn emdn_get_bbox Get the bounding box (geographic extent) of a
#' coverage in World Geodetic System 1984 (WGS84) Coordinate Reference System
#' (or `EPSG:4326`).
#' @export
emdn_get_WGS84bbox <- function(summary) {
  summary$getWGS84BoundingBox()$WGS84BoundingBox$getBBOX()
}

#' @describeIn emdn_get_bbox Get the value representing nil values in a
#' coverage.
#' @export
emdn_get_band_nil_values <- function(summary) {
  fields <- summary$getDescription()$rangeType$field
  nil_val <- fields %>%
    purrr::map(
      ~ .x$nilValues$nilValue[[1]]$value
    )

  nil_val <- nil_val %>%
    purrr::map_dbl(
      ~ ifelse(
        is.null(.x),
        NA,
        as.numeric(.x)
      )
    )

  names(nil_val) <- fields %>%
    purrr::map_chr(
      ~ .x$description$value
    )

  return(nil_val)
}

#' @describeIn emdn_get_bbox Get the band descriptions of a coverage.
#' @export
emdn_get_band_descriptions <- function(summary) {
  fields <- summary$getDescription()$rangeType$field
  band_names <- fields %>%
    purrr::map_chr(~ .x$description$value)

  attr(band_names, "uom") <- fields %>%
    purrr::map_chr(~ .x$uom$attrs$code)

  return(band_names)
}

#' @describeIn emdn_get_bbox Get the units of measurement of the data contained in
#' the bands values of a coverage.
#' @export
emdn_get_band_uom <- function(summary) {
  fields <- summary$getDescription()$rangeType$field
  uom <- fields %>%
    purrr::map_chr(~ .x$uom$attrs$code)

  names(uom) <- fields %>%
    purrr::map_chr(~ .x$description$value)

  return(uom)
}

#' @describeIn emdn_get_bbox Get the range of values of the data contained in
#' the bands of the coverage.
#' @export
emdn_get_band_constraints <- function(summary) {
  fields <- summary$getDescription()$rangeType$field
  constraints <- fields %>%
    purrr::map(
      ~ .x$constraint$AllowedValues$interval$value %>%
        strsplit(" ") %>%
        unlist() %>%
        as.numeric()
    )
  names(constraints) <- fields %>%
    purrr::map_chr(~ .x$description$value)

  return(constraints)
}

#' @describeIn emdn_get_bbox Get the grid size of a coverage.
#' @export
emdn_get_grid_size <- function(summary) {
  resolution <- emdn_get_resolution(summary)
  bbox <- summary$BoundingBox$BoundingBox$getBBOX()

  c(
    ncol = (bbox[["xmax"]] - bbox[["xmin"]]) / resolution[["x"]],
    nrow = (bbox[["ymax"]] - bbox[["ymin"]]) / resolution[["y"]]
  ) %>%
    round()
}

#' @describeIn emdn_get_bbox Get the resolution of a coverage.
#' @export
emdn_get_resolution <- function(summary) {
  offset_vector <- summary$getDescription()$domainSet$offsetVector

  if (length(offset_vector) == 1L) {
    resolution <- offset_vector$value %>%
      strsplit(" ") %>%
      unlist() %>%
      as.numeric() %>%
      abs()
  } else {
    resolution <- purrr::map_dbl(
      offset_vector,
      ~ .x$value %>%
        strsplit(" ") %>%
        unlist() %>%
        as.numeric() %>%
        sum() %>%
        abs()
    )
  }

  axis_order <- emdn_get_coverage_function(summary)$axis_order

  is_x_axis <- purrr::map_lgl(
    axis_order,
    ~ grepl(.x, "x|2")
  )

  if (sum(is_x_axis) != 1L) {
    cli::cli_warn(
      c(
        "!" = "Unable to detecting axis order. Defaulting to {.val x}, {.val y}"
      )
    )
    names(resolution) <- c("x", "y")
  } else {
    res_names <- c("y", "y")
    res_names[is_x_axis] <- "x"
    names(resolution) <- res_names
  }

  uom <- summary$getDescription()$boundedBy$attrs$uomLabels %>%
    strsplit(" ") %>%
    unlist()

  uom <- uom[emdn_get_dimension_types(summary) == "geographic"]

  attr(resolution, "uom") <- uom

  return(resolution)
}

#' @describeIn emdn_get_bbox Get the grid function of a coverage.
#' @export
emdn_get_coverage_function <- function(summary) {
  grid_function <- summary$getDescription()$coverageFunction[[1]]

  list(
    sequence_rule = grid_function[["sequenceRule"]]$value,
    start_point = grid_function[["startPoint"]]$value %>%
      strsplit(" ") %>%
      unlist() %>%
      as.numeric(),
    axis_order = grid_function[["sequenceRule"]]$attrs$axisOrder %>%
      strsplit(" ") %>%
      unlist()
  )
}

#' @describeIn emdn_get_bbox Get the temporal extent of a coverage.
#' @export
emdn_get_temporal_extent <- function(summary) {
  dim_df <- emdn_get_dimensions_info(summary, format = "tibble")

  if (any(dim_df$type == "temporal")) {
    dim_df$range[dim_df$type == "temporal"] %>%
      strsplit(" - ") %>%
      unlist()
  } else {
    NA
  }
}

#' @describeIn emdn_get_bbox Get the vertical (elevation) extent of a coverage.
#' @export
emdn_get_vertical_extent <- function(summary) {
  dim_df <- emdn_get_dimensions_info(summary, format = "tibble")

  if (any(dim_df$type == "vertical")) {
    dim_df$range[dim_df$type == "vertical"] %>%
      strsplit(" - ") %>%
      unlist()
  } else {
    NA
  }
}

#' @describeIn emdn_get_bbox Get information on dimensions of a coverage in
#' various formats. Information includes dimension label, type, unit and
#' range (in tibble format).
#' @export
emdn_get_dimensions_info <- function(
  summary,
  format = c(
    "character",
    "list",
    "tibble"
  ),
  include_coeffs = FALSE
) {
  format <- match.arg(format)
  dimensions <- summary$getDimensions()

  # internal format specific processing functions
  process_character <- function(x) {
    purrr::map_chr(
      x,
      ~ glue::glue(
        '{tolower(.x[["label"]])}',
        '({tolower(.x[["uom"]])}):',
        '{tolower(.x[["type"]])}'
      )
    ) %>%
      glue::glue_collapse("; ")
  }

  process_list <- function(x, include_coeffs = FALSE) {
    if (include_coeffs) {
      out <- x
    } else {
      out <- purrr::map(x, ~ head(.x, 3))
    }

    stats::setNames(out, glue::glue("dim_{seq_along(out)}"))
  }

  process_tibble <- function(x) {
    tibble::tibble(
      dimension = seq_along(x),
      label = purrr::map_chr(x, ~ purrr::pluck(.x, "label")) %>%
        tolower(),
      uom = purrr::map_chr(x, ~ purrr::pluck(.x, "uom")) %>%
        tolower(),
      type = purrr::map_chr(x, ~ purrr::pluck(.x, "type")) %>%
        tolower(),
      range = purrr::map(
        x,
        ~ purrr::pluck(.x, "coefficients") %>%
          unlist()
      ) %>%
        purrr::map_if(
          function(x) {
            !is.null(x)
          },
          ~ range(.x) %>%
            paste(collapse = " - ")
        ) %>%
        purrr::map_if(is.null, function(x) {
          NA
        }) %>%
        unlist()
    )
  }

  switch(
    format,
    "character" = process_character(dimensions),
    "list" = process_list(dimensions, include_coeffs = include_coeffs),
    "tibble" = process_tibble(dimensions)
  )
}

#' @describeIn emdn_get_bbox Get coverage dimension names (labels) and units.
#' @export
emdn_get_dimensions_names <- function(summary) {
  dimensions <- summary$getDescription()$boundedBy$attrs

  paste(
    paste0(
      unlist(strsplit(dimensions$axisLabels, " ")),
      " (",
      unlist(strsplit(dimensions$uomLabels, " ")),
      ")"
    ),
    collapse = ", "
  )
}

#' @describeIn emdn_get_bbox Get number of coverage dimensions.
#' @export
emdn_get_dimensions_n <- function(summary) {
  summary$getDimensions() %>% length()
}

#' @describeIn emdn_get_bbox Get dimensions types of a coverage.
#' @export
emdn_get_dimension_types <- function(summary) {
  dimensions <- summary$getDimensions()

  purrr::map_chr(dimensions, ~ purrr::pluck(.x, "type"))
}

# ---- unexported-utils ----
conc_bbox <- function(bbox) {
  paste(round(bbox, 2), collapse = ", ")
}

extr_bbox_crs <- function(summary) {
  bbox_crs <- summary$getBoundingBox()$BoundingBox$attrs$crs

  if (!is.null(bbox_crs)) {
    crs_parts <- unlist(strsplit(bbox_crs, "EPSG:"))
    if (length(crs_parts) == 2) {
      srid <- as.integer(crs_parts[2])
      if (!is.na(srid)) bbox_crs <- sf::st_crs(srid)
    } else {
      bbox_crs <- sf::st_crs(4326)
    }
  } else {
    bbox_crs <- sf::st_crs(4326)
  }
  return(bbox_crs)
}

conc_resolution <- function(x) {
  uom <- attr(x, "uom")
  paste(x, uom, collapse = " x ")
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

conc_band_uom <- function(x) {
  if (length(unique(x)) == 1L) {
    return(unique(x))
  }

  return(paste(x, collapse = ", "))
}

conc_nil_value <- function(x) {
  if (length(unique(x)) == 1L) {
    return(unique(x))
  }

  return(paste(x, collapse = ", "))
}

conc_constraint <- function(x) {
  x <- purrr::map_chr(
    x,
    ~ paste(.x, collapse = "-")
  )

  if (length(unique(x)) == 1L) {
    return(unique(x))
  }

  return(paste(x, collapse = ", "))
}
