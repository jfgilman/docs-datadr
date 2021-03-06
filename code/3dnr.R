## 
irisDdf <- ddf(iris)
# divide irisDdf by species
bySpecies <- divide(irisDdf, by = "Species", update = TRUE)

## 
bySpecies

## 
# divide irisDdf by species using condDiv()
bySpecies <- divide(irisDdf, by = condDiv("Species"), update = TRUE)

## 
# look at a subset of bySpecies
bySpecies[[1]]

## 
# get the split variable (Species) for some subsets
getSplitVars(bySpecies[[1]])
getSplitVars(bySpecies[[2]])

## 
# look at bySpecies keys
getKeys(bySpecies)

## 
# divide iris data into random subsets of 10 rows per subset
set.seed(123)
byRandom <- divide(bySpecies, by = rrDiv(10), update = TRUE)

## 
byRandom

## 
par(mar = c(4.1, 4.1, 1, 0.2))
# plot distribution of the number of rows in each subset
qplot(y = splitRowDistn(byRandom),
  xlab = "percentile", ylab = "number of rows in subset")

## 
head(getKeys(byRandom))

## 
summary(bySpecies)$Sepal.Length$range

## 
irisDdfSlCut <- addTransform(irisDdf, function(v) {
  v$slCut <- cut(v$Sepal.Length, seq(0, 8, by = 1))
  v
})
irisDdfSlCut[[1]]

## 
# divide on Species and slCut
bySpeciesSL <- divide(irisDdfSlCut, by = c("Species", "slCut"))

## 
bySpeciesSL[[3]]

## 
getSplitVars(bySpeciesSL[[3]])

## 
# divide iris data by species, spilling to new key-value after 12 rows
bySpeciesSpill <- divide(irisDdf, by = "Species", spill = 12, update = TRUE)

## 
# look at some subsets
bySpeciesSpill[[1]]
bySpeciesSpill[[5]]

## 
# divide iris data by species, spill, and filter out subsets with <=5 rows
bySpeciesFilter <- divide(irisDdf, by = "Species", spill = 12,
  filter = function(v) nrow(v) > 5, update = TRUE)
bySpeciesFilter

## 
irisDdf <- ddf(iris)
bySpecies <- divide(irisDdf, by = "Species", update = TRUE)

## 
# apply mean petal width transformation
mpw <- addTransform(bySpecies, function(v) mean(v$Petal.Width))
# recombine using the default combine=combCollect
recombine(mpw)

## 
recombine(mpw, combRbind)

## 
recombine(mpw, combDdo)

## 
data(adult)
# turn adult into a ddf
adultDdf <- ddf(adult, update = TRUE)
adultDdf
#look at the names
names(adultDdf)

## 
library(lattice)
edTable <- summary(adultDdf)$education$freqTable
edTable$value <- with(edTable, reorder(value, Freq, mean))
dotplot(value ~ Freq, data = edTable)

## 
# make a transformation to group some education levels
edGroups <- function(v) {
  v$edGroup <- as.character(v$education)
  v$edGroup[v$edGroup %in% c("1st-4th", "5th-6th")] <- "Some-elementary"
  v$edGroup[v$edGroup %in% c("7th-8th", "9th")] <- "Some-middle"
  v$edGroup[v$edGroup %in% c("10th", "11th", "12th")] <- "Some-HS"
  v
}
# test it
adultDdfGroup <- addTransform(adultDdf, edGroups)
adultDdfGroup[[1]]

## 
# divide by edGroup and filter out "Preschool"
byEdGroup <- divide(adultDdfGroup, by = "edGroup",
  filterFn = function(x) x$edGroup[1] != "Preschool",
  update = TRUE)
byEdGroup

## 
# add transformation to count number of people in each education group
byEdGroupNrow <- addTransform(byEdGroup, function(x) nrow(x))
# recombine into a data frame
edGroupTable <- recombine(byEdGroupNrow, combRbind)
edGroupTable

## 
# compute male/female ratio by education group
byEdGroupSR <- addTransform(byEdGroup, function(x) {
  tab <- table(x$sex)
  data.frame(maleFemaleRatio = tab["Male"] / tab["Female"])
})
# recombine into a data frame
sexRatio <- recombine(byEdGroupSR, combRbind)
sexRatio

## 
# make dotplot of male/female ratio by education group
sexRatio$edGroup <- with(sexRatio, reorder(edGroup, maleFemaleRatio, mean))
dotplot(edGroup ~ maleFemaleRatio, data = sexRatio)

## 
# fit a glm to the original adult data frame
rglm <- glm(incomebin ~ educationnum + hoursperweek + sex, data = adult, family = binomial())
summary(rglm)$coefficients

## 
rrAdult <- divide(adultDdf, by = rrDiv(1000), update = TRUE,
  postTransFn = function(x)
    x[,c("incomebin", "educationnum", "hoursperweek", "sex")])

## 
adultGlm <- addTransform(rrAdult, function(x)
  drGLM(incomebin ~ educationnum + hoursperweek + sex,
    data = x, family = binomial()))
recombine(adultGlm, combMeanCoef)

## 
## # add bag of little bootstraps transformation
## adultBlb <- addTransform(rrAdult, function(x) {
##   drBLB(x,
##     statistic = function(x, weights)
##       coef(glm(incomebin ~ educationnum + hoursperweek + sex,
##         data = x, weights = weights, family = binomial())),
##     metric = function(x)
##       quantile(x, c(0.05, 0.95)),
##     R = 100,
##     n = nrow(rrAdult)
##   )
## })
## # compute the mean of the resulting CI limits
## coefs <- recombine(adultBlb, combMean)
## matrix(coefs, ncol = 2, byrow = TRUE)

