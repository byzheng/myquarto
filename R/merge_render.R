temp_render_dir <- function(prefix = "merge_render_") {
    stopifnot(is.character(prefix), length(prefix) == 1)

    dir <- tempfile(pattern = prefix)
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)

    normalizePath(dir, winslash = "/", mustWork = TRUE)
}

has_quarto_project <- function(path = ".") {
    stopifnot(is.character(path), length(path) == 1)

    if (!requireNamespace("rprojroot", quietly = TRUE)) {
        stop("Package `rprojroot` is required for `has_quarto_project()`.")
    }

    tryCatch(
        {
            rprojroot::find_root(
                rprojroot::has_file("_quarto.yml"),
                path = path
            )
            TRUE
        },
        error = function(e) FALSE
    )
}


find_quarto_project <- function(path = ".") {
    stopifnot(is.character(path), length(path) == 1)

    if (!requireNamespace("rprojroot", quietly = TRUE)) {
        stop("Package `rprojroot` is required for `find_quarto_project()`.")
    }

    tryCatch(
        rprojroot::find_root(
            rprojroot::has_file("_quarto.yml"),
            path = path
        ),
        error = function(e) NULL
    )
}

strip_qmd_yaml <- function(lines) {
    if (length(lines) == 0) {
        return(character())
    }

    first_idx <- which(nzchar(trimws(lines)))[1]

    if (is.na(first_idx)) {
        return(character())
    }

    first <- trimws(lines[first_idx])

    if (identical(first, "---")) {
        if (first_idx < length(lines)) {
            rest <- trimws(lines[(first_idx + 1):length(lines)])
            end_rel <- which(rest == "---")[1]

            if (!is.na(end_rel)) {
                end <- first_idx + end_rel

                if (end < length(lines)) {
                    return(lines[(end + 1):length(lines)])
                } else {
                    return(character())
                }
            }
        }
    }

    if (grepl("^```\\{yaml", first)) {
        if (first_idx < length(lines)) {
            rest <- trimws(lines[(first_idx + 1):length(lines)])
            end_rel <- which(rest == "```")[1]

            if (!is.na(end_rel)) {
                end <- first_idx + end_rel

                if (end < length(lines)) {
                    return(lines[(end + 1):length(lines)])
                } else {
                    return(character())
                }
            }
        }
    }

    lines
}


trim_blank_lines <- function(lines) {
    if (length(lines) == 0) {
        return(character())
    }

    while (length(lines) > 0 && !nzchar(trimws(lines[1]))) {
        lines <- lines[-1]
    }

    while (length(lines) > 0 && !nzchar(trimws(lines[length(lines)]))) {
        lines <- lines[-length(lines)]
    }

    lines
}

infer_quarto_format <- function(output_path) {
    ext <- tolower(tools::file_ext(output_path))

    switch(
        ext,
        html = "html",
        htm  = "html",
        md   = "markdown",
        qmd  = "qmd",
        docx = "docx",
        pdf  = "pdf",
        tex  = "latex",
        stop(
            sprintf(
                "Cannot infer `output_format` from extension '.%s'. Please supply `output_format` explicitly.",
                ext
            ),
            call. = FALSE
        )
    )
}

expected_extensions <- function(output_format) {
    output_format <- tolower(output_format)

    switch(
        output_format,
        html     = c("html", "htm"),
        markdown = c("md"),
        gfm      = c("md"),
        commonmark = c("md"),
        docx     = c("docx"),
        pdf      = c("pdf"),
        latex    = c("tex"),
        qmd      = c("qmd"),
        stop(
            sprintf(
                "Do not know expected extension for `output_format = '%s'`.",
                output_format
            ),
            call. = FALSE
        )
    )
}


validate_output_format <- function(output_path, output_format) {
    ext <- tolower(tools::file_ext(output_path))

    if (!nzchar(ext)) {
        stop("`output_path` must include a file extension.", call. = FALSE)
    }

    expected <- expected_extensions(output_format)

    if (!ext %in% expected) {
        stop(
            sprintf(
                "`output_path` extension '.%s' is inconsistent with `output_format = '%s'`. Expected extension: %s.",
                ext,
                output_format,
                paste0(".", expected, collapse = ", ")
            ),
            call. = FALSE
        )
    }

    invisible(TRUE)
}


make_merged_yaml <- function(title = NULL, output_format = NULL) {
    yaml <- character()

    if (!is.null(title)) {
        yaml <- c(yaml, paste0("title: ", encode_yml_string(title)))
    }

    if (!is.null(output_format) && !identical(output_format, "qmd")) {
        yaml <- c(yaml, "format:", paste0("  ", output_format, ": default"))
    }

    if (length(yaml) == 0) {
        return(character())
    }

    c("---", yaml, "---", "")
}

encode_yml_string <- function(x) {
    stopifnot(is.character(x), length(x) == 1)

    x <- gsub("\\\\", "\\\\\\\\", x)
    x <- gsub('"', '\\"', x)

    paste0('"', x, '"')
}


locate_rendered_file <- function(
    quarto_result,
    render_dir,
    render_stem,
    output_format
) {
    # Prefer quarto's returned path if it is a file.
    if (is.character(quarto_result) && length(quarto_result) >= 1) {
        candidates <- quarto_result[file.exists(quarto_result)]

        if (length(candidates) >= 1) {
            return(normalizePath(candidates[1], winslash = "/", mustWork = TRUE))
        }
    }

    exts <- expected_extensions(output_format)

    candidates <- file.path(
        render_dir,
        paste0(render_stem, ".", exts)
    )

    existing <- candidates[file.exists(candidates)]

    if (length(existing) >= 1) {
        return(normalizePath(existing[1], winslash = "/", mustWork = TRUE))
    }

    stop(
        paste0(
            "Could not locate rendered output. ",
            "Quarto may have written to a project-specific output directory. ",
            "Consider checking the return value of `quarto::quarto_render()` ",
            "or setting a simpler `render_dir`."
        ),
        call. = FALSE
    )
}


#' Merge multiple Quarto QMD files and optionally render
#'
#' This function reads multiple `.qmd` files, removes their top-level YAML
#' headers, merges their bodies into a single temporary `.qmd`, and optionally
#' renders that file with `quarto::quarto_render()`.
#'
#' The important design distinction is:
#'
#' - `render_dir`: where the merged QMD is created and where Quarto is run.
#' - `output_path`: the final file path returned to the user.
#'
#' By default, `render_dir = "."`, so normal Quarto project behaviour is used.
#' If `render_dir` is inside a directory tree containing `_quarto.yml`, Quarto
#' may inherit that project configuration.
#'
#' To avoid inheriting `_quarto.yml`, use:
#'
#' `render_dir = temp_render_dir()`
#'
#' @param input_files Character vector of input `.qmd` file paths.
#' @param output_path Final output path. For example `"knowledge.md"`,
#'   `"report.html"`, `"paper.docx"`, or `"merged.qmd"`.
#' @param render_dir Directory where the merged source QMD is created and
#'   rendered. Defaults to `"."`.
#' @param title Optional title inserted into the merged QMD YAML header.
#' @param output_format Optional Quarto output format. If `NULL`, the format
#'   is inferred from `output_path`. If supplied, it must be consistent with
#'   the extension of `output_path`.
#' @param overwrite Logical. If `TRUE`, overwrite `output_path` if it exists.
#' @param render Logical. If `TRUE`, render the merged QMD. If `FALSE`,
#'   write the merged QMD directly to `output_path`; in that case,
#'   `output_path` must end in `.qmd`.
#' @param quiet Logical. Passed to `quarto::quarto_render()`.
#' @param ... Additional arguments passed to `quarto::quarto_render()`.
#'
#' @return Invisibly returns `output_path`.
#'
#' @export
merge_render <- function(
    input_files,
    output_path,
    render_dir = ".",
    title = NULL,
    output_format = "html",
    overwrite = FALSE,
    ...
) {
    # ---- validate basic inputs ----

    if (missing(input_files) || length(input_files) == 0) {
        stop("`input_files` must contain at least one file.", call. = FALSE)
    }

    stopifnot(is.character(input_files))
    stopifnot(is.character(output_path), length(output_path) == 1)
    stopifnot(is.character(render_dir), length(render_dir) == 1)
    stopifnot(is.null(title) || (is.character(title) && length(title) == 1))
    stopifnot(is.null(output_format) || (is.character(output_format) && length(output_format) == 1))
    stopifnot(is.logical(overwrite), length(overwrite) == 1)
    input_files <- normalizePath(input_files, winslash = "/", mustWork = TRUE)

    for (f in input_files) {
        if (tolower(tools::file_ext(f)) != "qmd") {
            stop(sprintf("Not a `.qmd` file: %s", f), call. = FALSE)
        }
    }

    output_dir <- dirname(output_path)

    if (!dir.exists(output_dir)) {
        dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
    }

    if (file.exists(output_path) && !overwrite) {
        stop(
            sprintf(
                "`output_path` already exists: %s. Use `overwrite = TRUE` to replace it.",
                output_path
            ),
            call. = FALSE
        )
    }

    # ---- determine output format ----

    inferred_format <- infer_quarto_format(output_path)

    if (!is.null(output_format)) {
        validate_output_format(output_path, output_format)
    } else {
        output_format <- inferred_format
    }

    output_format <- tolower(output_format)
    # ---- validate output_path extension ----
    if (!(tools::file_ext(output_path) %in% expected_extensions(output_format))) {
        stop(
            sprintf(
                "`output_path` extension does not match `output_format = '%s'`: %s",
                output_format,
                output_path
            ),
            call. = FALSE
        )
    }
    # ---- prepare render directory ----

    if (!dir.exists(render_dir)) {
        dir.create(render_dir, recursive = TRUE, showWarnings = FALSE)
    }

    render_dir <- normalizePath(render_dir, winslash = "/", mustWork = TRUE)

    # ---- merge contents ----
    contents <- lapply(input_files, function(f) {
        lines <- readLines(f, warn = FALSE)
        lines <- strip_qmd_yaml(lines)
        trim_blank_lines(lines)
    })

    merged_body <- unlist(
        lapply(seq_along(contents), function(i) {
            if (length(contents[[i]]) == 0) {
                return(character())
            }

            c(contents[[i]], "")
        }),
        use.names = FALSE
    )

    merged_body <- trim_blank_lines(merged_body)

    yaml <- make_merged_yaml(
        title = title,
        output_format = output_format
    )

    final_lines <- c(yaml, merged_body)

    # ---- create merged QMD inside render_dir ----

    render_stem <- tools::file_path_sans_ext(basename(output_path))

    if (!nzchar(render_stem)) {
        render_stem <- "merged"
    }

    merged_qmd <- file.path(render_dir, paste0(render_stem, ".qmd"))

    if (file.exists(merged_qmd) && !overwrite) {
        stop(
            sprintf("File already exists: %s", merged_qmd),
            call. = FALSE
        )
    }
    writeLines(final_lines, merged_qmd, useBytes = TRUE)

    # ---- render ----

    if (!requireNamespace("quarto", quietly = TRUE)) {
        stop("Package `quarto` is required when `render = TRUE`.", call. = FALSE)
    }

    # Use a render-local output filename. The final artefact is copied to
    # output_path below.
    render_output_name <- basename(output_path)

    quarto_result <- quarto::quarto_render(
        input = merged_qmd,
        output_format = output_format,
        output_file = render_output_name,
        ...
    )

    render_output <- locate_rendered_file(
        quarto_result = quarto_result,
        render_dir = render_dir,
        render_stem = render_stem,
        output_format = output_format
    )

    # ---- deliver final artefact ----

    ok <- file.copy(
        from = render_output,
        to = output_path,
        overwrite = overwrite
    )

    if (!ok) {
        stop(
            sprintf(
                "Failed to copy rendered output from '%s' to '%s'.",
                render_output,
                output_path
            ),
            call. = FALSE
        )
    }

    invisible(normalizePath(output_path, winslash = "/", mustWork = TRUE))
}

