# Render any content in collapsible callouts

Wraps a list of content blocks (text, plots, tables, htmlwidgets,
Markdown) into Quarto callouts with optional collapse.

## Usage

``` r
render_callout_content(
  content_list,
  titles = names(content_list),
  callout_type = "note",
  collapse = TRUE
)
```

## Arguments

- content_list:

  List of R objects. Can be ggplot, HTML widget, character text, or
  Markdown.

- titles:

  Character vector of unique titles. Defaults to list names or Section
  1,2,...

- callout_type:

  Callout type: "note", "tip", "warning", etc.

- collapse:

  Logical. Should callouts start collapsed? Default TRUE.

## Value

HTML output for Quarto (asis)
