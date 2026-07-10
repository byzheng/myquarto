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
    dir.create(render_dir)

    merged_qmd <- file.path(outdir, "mymerged.qmd")
    if (file.exists(merged_qmd)) file.remove(merged_qmd)
    
    merged_path <- merge_render(
        input_files = c(f1, f2),
        output_path = merged_qmd,
        render_dir = render_dir,
        render = FALSE
    )

    expect_true(file.exists(merged_qmd))
    expect_equal(merged_path, normalizePath(merged_qmd, winslash = "/", mustWork = TRUE))

    txt <- readLines(merged_qmd)

    # should contain headings from both files
    expect_true(any(grepl("# A", txt)))
    expect_true(any(grepl("# B", txt)))

    # top-level YAML from source files should be stripped
    expect_false(any(grepl("^title:\\s*Test1$", txt)))
    expect_false(any(grepl("^title:\\s*Test2$", txt)))
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
            output_format = "html",
            render = FALSE
        ),
        "inconsistent with `output_format = 'html'`"
    )
})
