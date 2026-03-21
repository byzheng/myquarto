test_that("render_callout_ui returns knit_asis HTML with controls", {
    expect_no_error({
        out <- render_callout_ui(
          description = "My controls",
          button_expand_label = "Open",
          button_collapse_label = "Close"
        )
    })
})

test_that("render_callout_content wraps content in callouts", {
    content_list <- list(
      htmltools::HTML("<span>Block A</span>"),
      htmltools::HTML("<span>Block B</span>")
    )

    expect_no_error({
    out <- render_callout_content(
      content_list = content_list,
      titles = c("One", "Two"),
      callout_type = "tip",
      collapse = FALSE
    )
    })


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
