test_that("render_callout_ui returns knit_asis HTML with controls", {
  out <- render_callout_ui(
    description = "My controls",
    button_expand_label = "Open",
    button_collapse_label = "Close"
  )

  out_chr <- as.character(out)

  expect_s3_class(out, "knit_asis")
  expect_match(out_chr, "My controls", fixed = TRUE)
  expect_match(out_chr, "expandAllCallouts\\(\\)")
  expect_match(out_chr, "collapseAllCallouts\\(\\)")
  expect_match(out_chr, ">Open<", fixed = TRUE)
  expect_match(out_chr, ">Close<", fixed = TRUE)
})

test_that("render_callout_content wraps content in callouts", {
  content_list <- list(
    htmltools::HTML("<span>Block A</span>"),
    htmltools::HTML("<span>Block B</span>")
  )

  out <- render_callout_content(
    content_list = content_list,
    titles = c("One", "Two"),
    callout_type = "tip",
    collapse = FALSE
  )

  out_chr <- as.character(out)

  expect_s3_class(out, "knit_asis")
  expect_match(out_chr, "\\{\\.callout-tip collapse=\"false\"\\}")
  expect_match(out_chr, "### One", fixed = TRUE)
  expect_match(out_chr, "### Two", fixed = TRUE)
  expect_match(out_chr, "Block A", fixed = TRUE)
  expect_match(out_chr, "Block B", fixed = TRUE)
})

test_that("render_callout_content rejects duplicate titles", {
  content_list <- list("A", "B")

  expect_error(
    render_callout_content(
      content_list = content_list,
      titles = c("Same", "Same")
    ),
    "must not contain duplicates"
  )
})

test_that("render_callout_content accepts ggplot objects", {
  skip_if_not_installed("ggplot2")

  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point()

  out <- render_callout_content(
    content_list = list(p),
    titles = "Scatter"
  )

  out_chr <- as.character(out)

  expect_s3_class(out, "knit_asis")
  expect_match(out_chr, "### Scatter", fixed = TRUE)
  expect_match(out_chr, "\\{\\.callout-note collapse=\"true\"\\}")
})