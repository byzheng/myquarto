callout_dependency <- function() {
    dep_src <- system.file("quarto", package = "myquarto")
    if (!nzchar(dep_src)) {
        dep_src <- "inst/quarto"
    }

    htmltools::htmlDependency(
        name = "myquarto",
        version = "1.0",
        src = c(file = dep_src),
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

    out <- htmltools::attachDependencies(out, dep)
    rendered <- htmltools::renderTags(out)
    
    knitr::asis_output(rendered$html, meta = rendered$dependencies)
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
    cat("\r\n\r\n")
    i <- 2
    for (i in seq(along = content_list)) {
        content <- content_list[[i]]
        if (
            !(inherits(content, c("gg", "patchwork", "htmlwidget")) ||
            is.data.frame(content) ||
            is.character(content))
        ) {
            warning("Unsupported content type: ", class(content)[1], call. = FALSE)
            next
        }

        block_header <- sprintf(
            '::: {.callout-%s collapse="%s"}\r\n\r\n### %s\n\n',
            callout_type,
            collapse_value,
            titles[i]
        )
        cat(block_header)

        
        content_text <- if (inherits(content, c("gg", "patchwork", "htmlwidget"))) {
            print(content)
        }  else if (is.data.frame(content)) {
            cat("\r\n")
            cat(paste(knitr::kable(content, format = "markdown"), collapse = "\r\n"))
            cat("\r\n")
        } else if (is.character(content)) {
            cat(paste(content, collapse = "\n"))
        }

        cat("\r\n\r\n")
        cat(":::\r\n\r\n")
    }
    return(invisible())
}

