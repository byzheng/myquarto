# Merge multiple Quarto QMD files and optionally render

This function reads multiple `.qmd` files, removes their top-level YAML
headers, merges their bodies into a single temporary `.qmd`, and
optionally renders that file with
[`quarto::quarto_render()`](https://quarto-dev.github.io/quarto-r/reference/quarto_render.html).

## Usage

``` r
merge_render(
  input_files,
  output_path,
  render_dir = ".",
  title = NULL,
  output_format = "html",
  overwrite = FALSE,
  ...
)
```

## Arguments

- input_files:

  Character vector of input `.qmd` file paths.

- output_path:

  Final output path. For example `"knowledge.md"`, `"report.html"`,
  `"paper.docx"`, or `"merged.qmd"`.

- render_dir:

  Directory where the merged source QMD is created and rendered.
  Defaults to `"."`.

- title:

  Optional title inserted into the merged QMD YAML header.

- output_format:

  Optional Quarto output format. If `NULL`, the format is inferred from
  `output_path`. If supplied, it must be consistent with the extension
  of `output_path`.

- overwrite:

  Logical. If `TRUE`, overwrite `output_path` if it exists.

- ...:

  Additional arguments passed to
  [`quarto::quarto_render()`](https://quarto-dev.github.io/quarto-r/reference/quarto_render.html).

## Value

Invisibly returns `output_path`.

## Details

The important design distinction is:

- `render_dir`: where the merged QMD is created and where Quarto is run.

- `output_path`: the final file path returned to the user.

By default, `render_dir = "."`, so normal Quarto project behaviour is
used. If `render_dir` is inside a directory tree containing
`_quarto.yml`, Quarto may inherit that project configuration.

To avoid inheriting `_quarto.yml`, use:

`render_dir = temp_render_dir()`
