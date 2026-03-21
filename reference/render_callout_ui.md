# Render Callout UI

Creates Expand/Collapse All buttons for callout sections in Quarto.

## Usage

``` r
render_callout_ui(
  description = "Use the buttons below to expand or collapse all sections.",
  button_expand_label = "Expand All",
  button_collapse_label = "Collapse All"
)
```

## Arguments

- description:

  Character. Text shown above buttons.

- button_expand_label:

  Character. Label for the expand button.

- button_collapse_label:

  Character. Label for the collapse button.

## Value

HTML output for Quarto (asis).
