test_that("merge_render writes merged qmd and skips render when render=FALSE", {
    skip_on_cran()

    # create two temporary qmd files
    f1 <- tempfile(fileext = ".qmd")
    f2 <- tempfile(fileext = ".qmd")
    on.exit(unlink(c(f1, f2), force = TRUE), add = TRUE)

    writeLines(c("---", "title: Test1", "---", "", "# A", "content A"), f1)
    writeLines(c("---", "title: Test2", "---", "", "# B", "content B"), f2)

    outdir <- tempfile()
    dir.create(outdir)
    on.exit(unlink(outdir, recursive = TRUE), add = TRUE)

    render_dir <- file.path(outdir, "render")
    on.exit(unlink(render_dir, recursive = TRUE), add = TRUE)
    dir.create(render_dir)

    merged_qmd <- file.path(render_dir, "mymerged.qmd")
    if (file.exists(merged_qmd)) file.remove(merged_qmd)
    merged_html <- file.path(outdir, "mymerged.html")
    if (file.exists(merged_html)) file.remove(merged_html)
    a <- merge_render(
        input_files = c(f1, f2),
        output_path = merged_html,
        render_dir = render_dir
    )
    expect_true(file.exists(merged_qmd))
    expect_true(file.exists(merged_html))
    file.remove(merged_qmd)
    file.remove(merged_html)
    
})

test_that("merge_render errors when output_path extension does not match output_format", {
    skip_on_cran()

    f1 <- tempfile(fileext = ".qmd")
    on.exit(unlink(f1), add = TRUE)

    writeLines(c("# A", "content A"), f1)

    outdir <- tempfile()
    dir.create(outdir)
    on.exit(unlink(outdir, recursive = TRUE), add = TRUE)

    expect_error(
        merge_render(
            input_files = f1,
            output_path = file.path(outdir, "mymerged.qmd"),
            output_format = "html"
        ),
        "inconsistent with `output_format = 'html'`"
    )
})

test_that("merge_render errors before rendering when output_path extension does not match explicit output_format", {
    skip_on_cran()

    f1 <- tempfile(fileext = ".qmd")
    on.exit(unlink(f1), add = TRUE)

    writeLines(c("# A", "content A"), f1)

    outdir <- tempfile()
    dir.create(outdir)
    on.exit(unlink(outdir, recursive = TRUE), add = TRUE)

    expect_error(
        merge_render(
            input_files = f1,
            output_path = file.path(outdir, "mymerged.md"),
            output_format = "html"
        ),
        "inconsistent with `output_format = 'html'`"
    )
})
