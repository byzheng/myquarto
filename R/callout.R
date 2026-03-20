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
    
    html_list <- lapply(seq_along(content_list), function(i) {
        
        block_header <- htmltools::HTML(
        sprintf('::: {.callout-%s collapse="%s"}\n\n### %s\n\n', 
                callout_type, collapse_value, titles[i])
        )
        
        block_footer <- htmltools::HTML("\n:::\n")
        
        content <- content_list[[i]]
        
        # Convert different object types to HTML
        content_html <- switch(
        class(content)[1],
        
        "gg" = content,          # ggplot object → print as is
        "patchwork" = content,   # patchwork object
        "htmlwidget" = content,  # htmlwidget object
        "character" = htmltools::HTML(content), # plain text/markdown
        "data.frame" = knitr::kable(content, format = "html") |> htmltools::HTML(),
            content                     # fallback: try printing
        )
        
        htmltools::tagList(block_header, content_html, block_footer)
    })
    
    knitr::asis_output(
        paste(sapply(html_list, as.character), collapse = "\n\n")
    )
}
