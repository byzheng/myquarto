# myquarto

My personal quarto helper functions

## Installation

Currently on [Github](https://github.com/byzheng/myquarto) only. Install
with:

``` r
remotes::install_github('byzheng/myquarto')
```

## Usage

``` r
library(myquarto)
library(ggplot2)

render_callout_ui()

p <- ggplot(mtcars, aes(wt, mpg, color = factor(cyl))) +
    geom_point(size = 2.5) +
    theme_minimal()

render_callout_content(
    content_list = list(
        "A short text block.",
        p,
        head(mtcars, 5)
    ),
    titles = c("Overview", "Figure", "Data Preview"),
    callout_type = "tip",
    collapse = TRUE
)
```
