callout_dependency <- function() {
    htmltools::htmlDependency(
        name = "callout-tools",
        version = "1.0",
        src = system.file("quarto", package = "myquarto"),
        script = "callout.js",
        stylesheet = "callout.css"
    )
}


#' Render Callout UI
#'
#' Creates Expand/Collapse All buttons for callout sections in Quarto.
#'
#' @param description Character. Text shown above buttons.
#' @param button_expand_label Character. Label for the expand button.
#' @param button_collapse_label Character. Label for the collapse button.
#' @return HTML output for Quarto (asis).
#' @export
render_callout_ui <- function(
    description = "Use the buttons below to expand or collapse all sections.",
    button_expand_label = "Expand All",
    button_collapse_label = "Collapse All"
) {
    dep <- callout_dependency()
    
    out <- htmltools::tagList(
        dep,
        htmltools::tags$p(description),
        htmltools::tags$div(
        class = "mb-3",
        htmltools::tags$button(
            class = "btn btn-sm btn-outline-secondary me-2",
            onclick = "expandAllCallouts()",
            button_expand_label
        ),
        htmltools::tags$button(
            class = "btn btn-sm btn-outline-secondary",
            onclick = "collapseAllCallouts()",
            button_collapse_label
        )
        )
    )
    
    knitr::asis_output(as.character(out))
}


#' Render any content in collapsible callouts
#'
#' Wraps a list of content blocks (text, plots, tables, htmlwidgets, Markdown)
#' into Quarto callouts with optional collapse.
#'
#' @param content_list List of R objects. Can be ggplot, HTML widget, character text, or Markdown.
#' @param titles Character vector of unique titles. Defaults to list names or Section 1,2,...
#' @param callout_type Callout type: "note", "tip", "warning", etc.
#' @param collapse Logical. Should callouts start collapsed? Default TRUE.
#' @return HTML output for Quarto (asis)
#' @export
render_callout_content <- function(
    content_list,
    titles = names(content_list),
    callout_type = "note",
    collapse = TRUE
) {
    stopifnot(is.list(content_list), length(content_list) > 0)
    
    if (is.null(titles)) titles <- paste("Section", seq_along(content_list))
    stopifnot(length(titles) == length(content_list))
    if (anyDuplicated(titles)) {
        stop("`titles` must not contain duplicates.", call. = FALSE)
    }
    
    collapse_value <- if (collapse) "true" else "false"
    
    rendered_blocks <- lapply(seq_along(content_list), function(i) {
        block_header <- sprintf(
            '::: {.callout-%s collapse="%s"}\n\n### %s\n\n',
            callout_type,
            collapse_value,
            titles[i]
        )

        content <- content_list[[i]]

        content_text <- if (inherits(content, "ggplot")) {
            if (!requireNamespace("ggplot2", quietly = TRUE)) {
                stop("Package `ggplot2` is required to render ggplot objects.", call. = FALSE)
            }

            img_file <- tempfile("callout-plot-", fileext = ".png")
            on.exit(unlink(img_file), add = TRUE)
            ggplot2::ggsave(filename = img_file, plot = content, width = 7, height = 4, dpi = 96)

            as.character(
                htmltools::tags$img(
                    src = knitr::image_uri(img_file),
                    style = "max-width:100%;height:auto;"
                )
            )
        } else if (is.character(content)) {
            paste(content, collapse = "\n")
        } else if (is.data.frame(content)) {
            as.character(knitr::kable(content, format = "html"))
        } else {
            paste(as.character(content), collapse = "\n")
        }

        paste0(block_header, content_text, "\n\n:::\n")
    })

    knitr::asis_output(paste(unlist(rendered_blocks), collapse = "\n\n"))
}
