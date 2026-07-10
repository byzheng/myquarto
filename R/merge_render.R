#' Merge multiple Quarto QMD files and render
#'
#' Read multiple `.qmd` files, remove their YAML headers, combine their
#' contents into a single `.qmd` document, write that merged file to
#' `output_dir` and (optionally) render it with `quarto::quarto_render()`.
#'
#' @param input_files Character vector of input `.qmd` file paths.
#' @param output_file Filename (without extension) for the rendered output.
#'   If `NULL` the merged source file will be written as `merged.qmd` and
#'   Quarto's default output filename rules will apply.
#' @param output_dir Directory where the merged `.qmd` (and rendered output)
#'   will be written. Created if it does not exist.
#' @param title Optional title to add as a YAML header to the merged file.
#' @param output_format Target output format passed to `quarto::quarto_render()`.
#'   Defaults to `"html"`.
#' @param override Logical, overwrite existing merged file if TRUE.
#' @param render Logical, whether to call `quarto::quarto_render()` after
#'   writing the merged `.qmd`. Set to `FALSE` in tests to skip rendering.
#' @param ... Additional arguments passed to `quarto::quarto_render()`.
#'
#' @return Invisibly returns the merged `.qmd` path when `render = FALSE`,
#'   otherwise the result of `quarto::quarto_render()`.
#'
#' @export
merge_render <- function(
    input_files,
    output_file = NULL,
    output_dir = ".",
    title = NULL,
    output_format = "html",
    override = FALSE,
    render = TRUE,
    ...
) {
    if (length(input_files) == 0) {
        stop("`input_files` must contain at least one file")
    }
    stopifnot(is.character(input_files))
    stopifnot(is.null(output_file) || (is.character(output_file) && length(output_file) == 1))
    stopifnot(is.null(output_file) || tools::file_ext(output_file) == "")
    stopifnot(is.character(output_dir) && length(output_dir) == 1)
    stopifnot(is.null(title) || (is.character(title) && length(title) == 1))
    stopifnot(is.character(output_format) && length(output_format) == 1)
    stopifnot(is.logical(override) && length(override) == 1)
    stopifnot(is.logical(render) && length(render) == 1)

    # validate files exist and are .qmd
    for (f in input_files) {
        if (!file.exists(f)) stop(sprintf("Input file does not exist: %s", f))
        if (tolower(tools::file_ext(f)) != "qmd") stop(sprintf("Not a .qmd file: %s", f))
    }

    strip_yaml <- function(lines) {
        if (length(lines) == 0) return(character())
        # find first non-empty line
        first_idx <- which(nzchar(trimws(lines)))[1]
        if (is.na(first_idx)) return(character())
        first <- trimws(lines[first_idx])

        if (identical(first, "---")) {
            # find closing '---'
            rest <- trimws(lines[(first_idx + 1):length(lines)])
            end_rel <- which(rest == "---")[1]
            if (!is.na(end_rel)) {
                end <- first_idx + end_rel
                if (end < length(lines)) return(lines[(end + 1):length(lines)])
                return(character())
            }
        }

        if (grepl("^```\\{yaml", first)) {
            rest <- trimws(lines[(first_idx + 1):length(lines)])
            end_rel <- which(rest == "```")[1]
            if (!is.na(end_rel)) {
                end <- first_idx + end_rel
                if (end < length(lines)) return(lines[(end + 1):length(lines)])
                return(character())
            }
        }

        # no YAML-like header found at top
        lines
    }

    contents <- lapply(input_files, function(f) {
        lines <- readLines(f, warn = FALSE)
        stripped <- strip_yaml(lines)
        # trim leading/trailing empty lines
        if (length(stripped) > 0) {
            # remove leading empty
            while (length(stripped) > 0 && nzchar(trimws(stripped[1])) == FALSE) stripped <- stripped[-1]
            # remove trailing empty
            while (length(stripped) > 0 && nzchar(trimws(stripped[length(stripped)])) == FALSE) stripped <- stripped[-length(stripped)]
        }
        stripped
    })

    # add blank line between files
    merged_lines <- unlist(lapply(seq_along(contents), function(i) c(contents[[i]], "")), use.names = FALSE)
    # drop final blank added by above
    if (length(merged_lines) > 0 && identical(merged_lines[length(merged_lines)], "")) merged_lines <- merged_lines[-length(merged_lines)]

    yaml <- if (!is.null(title)) c("---", paste0('title: "', title, '"'), "---", "") else character()

    final_lines <- c(yaml, merged_lines)

    # ensure output dir exists
    if (is.null(output_dir) || output_dir == "") output_dir <- "."
    if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

    # determine a render filename in output_dir (quarto will base outputs on this file)
    render_basename <- if (!is.null(output_file)) paste0(tools::file_path_sans_ext(output_file), ".qmd") else "merged.qmd"
    render_path <- file.path(output_dir, render_basename)

    # write merged qmd directly into output_dir
    if (!file.exists(render_path) || override) {
        writeLines(final_lines, render_path)
    } else {
        stop(sprintf("Merged file already exists: %s. Use `override = TRUE` to overwrite.", render_path))
    }

    # render in the output directory so that output_file (a filename) is written there
    if (!render) {
        return(invisible(render_path))
    }
    quarto::quarto_render(
        input = render_path,
        output_file = output_file,
        output_format = output_format,
        ...
    )

    invisible(render_path)
}