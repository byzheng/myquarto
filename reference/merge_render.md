# Merge multiple Quarto QMD files and render

Read multiple `.qmd` files, remove their YAML headers, combine their
contents into a single `.qmd` document, write that merged file to
`output_dir` and (optionally) render it with
[`quarto::quarto_render()`](https://quarto-dev.github.io/quarto-r/reference/quarto_render.html).

## Usage

``` r
merge_render(
  input_files,
  output_file = NULL,
  output_dir = ".",
  title = NULL,
  output_format = "html",
  override = FALSE,
  render = TRUE,
  ...
)
```

## Arguments

- input_files:

  Character vector of input `.qmd` file paths.

- output_file:

  Filename (without extension) for the rendered output. If `NULL` the
  merged source file will be written as `merged.qmd` and Quarto's
  default output filename rules will apply.

- output_dir:

  Directory where the merged `.qmd` (and rendered output) will be
  written. Created if it does not exist.

- title:

  Optional title to add as a YAML header to the merged file.

- output_format:

  Target output format passed to
  [`quarto::quarto_render()`](https://quarto-dev.github.io/quarto-r/reference/quarto_render.html).
  Defaults to `"html"`.

- override:

  Logical, overwrite existing merged file if TRUE.

- render:

  Logical, whether to call
  [`quarto::quarto_render()`](https://quarto-dev.github.io/quarto-r/reference/quarto_render.html)
  after writing the merged `.qmd`. Set to `FALSE` in tests to skip
  rendering.

- ...:

  Additional arguments passed to
  [`quarto::quarto_render()`](https://quarto-dev.github.io/quarto-r/reference/quarto_render.html).

## Value

Invisibly returns the merged `.qmd` path when `render = FALSE`,
otherwise the result of
[`quarto::quarto_render()`](https://quarto-dev.github.io/quarto-r/reference/quarto_render.html).
