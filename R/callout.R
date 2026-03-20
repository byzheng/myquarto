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


#' Render Blocks in Callouts
#'
#' Wraps a list of text blocks in Quarto callouts with optional collapse.
#'
#' @param blocks List of text blocks.
#' @param titles Character vector of titles. Defaults to list names or Section 1,2,...
#' @param callout_type Callout type: "note", "tip", "warning", etc.
#' @param collapse Logical. Should callouts start collapsed? Default TRUE.
#' @return HTML output for Quarto (asis)
#' @export
#' @examples
#' blocks <- list(
#'   "Intro" = "This is the introduction section.",
#'   "Details" = "Here are the details, with multiple lines.\nYou can use Markdown!"
#' )
#' render_callout_blocks(blocks, callout_type = "tip", collapse = FALSE)
render_callout_blocks <- function(
  blocks,
  titles = names(blocks),
  callout_type = "note",
  collapse = TRUE
) {
    stopifnot(is.list(blocks), length(blocks) > 0)
    if (is.null(titles)) titles <- paste("Section", seq_along(blocks))
    stopifnot(length(titles) == length(blocks))
    collapse_value <- if (collapse) "true" else "false"

    html_list <- lapply(seq_along(blocks), function(i) {
        htmltools::tagList(
        htmltools::HTML(
            sprintf('::: {.callout-%s collapse="%s"}\n\n### %s\n\n', 
                    callout_type, collapse_value, titles[i])
        ),
        blocks[[i]],
        htmltools::HTML("\n:::\n")
        )
    })

    knitr::asis_output(paste(sapply(html_list, as.character), collapse = "\n\n"))
}
