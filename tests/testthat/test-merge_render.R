test_that("merge_render writes merged qmd and skips render when render=FALSE", {
    skip_on_cran()
    # create two temporary qmd files
    f1 <- tempfile(fileext = ".qmd")
    f2 <- tempfile(fileext = ".qmd")

    writeLines(c("---", "title: Test1", "---", "", "# A", "content A"), f1)
    writeLines(c("---", "title: Test2", "---", "", "# B", "content B"), f2)

    outdir <- tempfile()
    dir.create(outdir)
    on.exit(unlink(outdir, recursive = TRUE), add = TRUE)
    merged_qmd <- file.path(outdir, "mymerged.qmd")
    if (file.exists(merged_qmd)) file.remove(merged_qmd)    
    
    merged_path <- merge_render(c(f1, f2), output_file = "mymerged", output_dir = outdir, render = FALSE)
    expect_true(file.exists(merged_qmd))
    txt <- readLines(merged_qmd)
    # should contain headings from both files
    expect_true(any(grepl("# A", txt)))
    expect_true(any(grepl("# B", txt)))
})
