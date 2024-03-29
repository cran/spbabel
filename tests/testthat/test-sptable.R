
library(testthat)
library(spbabel)
data("mpoint1")
polytab <- spbabel::sptable(.wrld_simpl)
polynames <- c("object_", "branch_", "island_", "order_", "x_", "y_")
polytypes <- setNames(c("integer", "integer", "logical", "integer", "numeric", "numeric"), polynames)

linetab <- spbabel::sptable(as(.wrld_simpl, "SpatialLinesDataFrame"))
linenames <- c("object_", "branch_",  "order_", "x_", "y_")
linetypes <- setNames(c("integer",  "integer",  "integer", "numeric", "numeric"), linenames)

spts <- as(as(.wrld_simpl, "SpatialLinesDataFrame"), "SpatialPointsDataFrame")
pointtab <- spbabel::sptable(spts)
pointnames <- c("object_", "x_", "y_")
pointtypes <- setNames(c("integer",  "numeric", "numeric"), pointnames)

multitab <- spbabel::sptable(mpoint1)
multinames <- c("branch_", "object_", "x_", "y_")
multitypes <- setNames(c("integer", "integer",  "numeric", "numeric"), multinames)


context("safety catch in case the column order changes")
test_that("sptable names is the same", {
  expect_equal(names(polytab), polynames)
  expect_equal(names(linetab), linenames)

})



context("sptable")
test_that("sptable structure is sound", {
  expect_equal(sort(names(polytab)), sort(polynames))
  expect_equal(sapply(polytab, class)[polynames], polytypes)

  expect_equal(sort(names(linetab)), sort(linenames))
  expect_equal(sapply(linetab, class)[linenames], linetypes)
})

context("points")
test_that("sptable points structure is sound", {
  expect_true(all(pointnames %in% names(pointtab)))
  expect_equal(sapply(pointtab, class)[pointnames], pointtypes)

  expect_equal(sort(names(multitab)), sort(multinames))
  expect_equal(sapply(multitab, class)[multinames], multitypes)
})

context("holes")
test_that("hole checking", {
  expect_that(sptable(sp(holey)), is_a("tbl_df"))
})
