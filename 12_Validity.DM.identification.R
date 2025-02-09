#####################################################################################
# Project name : Validity of DM identification
# Task Purpose : 
#      1. Merge indicator from each database
#      2. Validity of PDE
#      3. Validity of MA
#      4. Validity of MBSF
# Final dataset : 
#       00
#####################################################################################

# in the directory
cd glp1off/sas_input

## using R
module load R
module load rstudio
rstudio

## Setting
#install.packages(c("MatchIt", "cobalt", "WeightIt", "haven", "optmatch", "sandwich", "lmtest", "marginaleffects", "data.table"))


setwd("/users/59883/c-mkim255-59883/glp1off/sas_input")

library(tidyverse)
library(haven)
library(lubridate)
library(dplyr)
library(ggplot2)
library(MatchIt)
library(cobalt)
library(WeightIt)
library(optmatch)
library(sandwich)
library(lmtest)
library(marginaleffects)

# loading sas dataset
df <- read_sas("studypop.sas7bdat")
tm <- read_sas("dm_tm.sas7bdat")
mbsf <- read_sas("dm_diabetes_cc.sas7bdat")
ma <- read_sas("dm_ma.sas7bdat")

# input.DM_TM | diabetes_tm | diabetes_tm_yr | diabetes_2nd_tm | diabetes_2nd_tm_yr
# input.DM_diabetes_cc | diabetes_cc | diabetes_cc_yr
# pde -> if offlabel_df1 = 0 then diabetes = 1
# input.DM_MA | diabetes_ma | diabetes_ma_yr 

#####################################################################################
#     1.    Merge indicator from each database
#####################################################################################

# 1. set study population 
id <- df %>% select(BENE_ID, SRVC_DT, offlabel_df1, offlabel_df5)

# 2. pde only indicator
id <- id %>% 
    mutate(
      dm.pde = ifelse(offlabel_df1 == 0, 1, 0)
    ) %>%
    rename(index.date = SRVC_DT)

# 3. TM indicator
tm <- tm %>% 
    rename(diabetes_1st_tm = diabetes_tm) %>%
    mutate(
      diabetes_tm = ifelse(diabetes_1st_tm == 1 | diabetes_2nd_tm == 1, 1, 0)
    )

dm.tm <- id %>%
    select(BENE_ID, index.date) %>%
    left_join(tm %>% select(BENE_ID, diabetes_tm, diabetes_tm_yr), by ="BENE_ID") %>%
    filter(year(index.date) == diabetes_tm_yr | year(index.date) - 1 == diabetes_tm_yr)
dm.tm <- dm.tm %>% select(-diabetes_tm_yr) %>% distinct()  # 34105
dm.tm <- dm.tm %>% mutate(dm.tm = ifelse(diabetes_tm == 1, 1, 0))

# MA indicator
dm.ma <- id %>%
    select(BENE_ID, index.date) %>%
    left_join(ma %>% select(BENE_ID, diabetes_ma, diabetes_ma_yr), by ="BENE_ID") %>%
    filter(year(index.date) == diabetes_ma_yr | year(index.date) - 1 == diabetes_ma_yr)
dm.ma <- dm.ma %>% select(-diabetes_ma_yr) %>% distinct()  # 52781
dm.ma <- dm.ma %>% mutate(dm.ma = ifelse(diabetes_ma ==1, 1, 0))

# mbsf indicator
dm.mbsf <- id %>%
    select(BENE_ID, index.date) %>%
    left_join(mbsf %>% select(BENE_ID, diabetes_cc, diabetes_cc_yr), by ="BENE_ID") %>%
    filter(year(index.date) == diabetes_cc_yr | year(index.date) - 1 == diabetes_cc_yr)
dm.mbsf <- dm.mbsf %>% select(-diabetes_cc_yr) %>% distinct()  # 36794
dm.mbsf <- dm.mbsf %>% mutate(dm.mbsf = ifelse(diabetes_cc == 1, 1, 0))


# merge with study population across all datasets
dm.val <- id %>%
  select(BENE_ID, offlabel_df5, index.date, dm.pde) %>%
  left_join(dm.tm %>% select(BENE_ID, dm.tm), by ="BENE_ID") %>%
  left_join(dm.ma %>% select(BENE_ID, dm.ma), by ="BENE_ID") %>%
  left_join(dm.mbsf %>% select(BENE_ID, dm.mbsf), by ="BENE_ID")
head(dm.val)

# address NA
dm.val$dm.tm <- ifelse(is.na(dm.val$dm.tm), 0, dm.val$dm.tm)
dm.val$dm.ma <- ifelse(is.na(dm.val$dm.ma), 0, dm.val$dm.ma)
dm.val$dm.mbsf <- ifelse(is.na(dm.val$dm.mbsf), 0, dm.val$dm.mbsf)

# check missingness (need to be no missingness)
mice::md.pattern(dm.val, plot=FALSE)

#####################################################################################
#     2.    Validity of PDE
#####################################################################################

# Create the 2x2 matrix
a <- dm.val %>% filter(dm.tm == 1 & dm.pde == 1) %>% count()
b <- dm.val %>% filter(dm.tm == 0 & dm.pde == 1) %>% count()
c <- dm.val %>% filter(dm.tm == 1 & dm.pde == 0) %>% count()
d <- dm.val %>% filter(dm.tm == 0 & dm.pde == 0) %>% count()

val.pde <- matrix(c(a, b, c, d), nrow = 2, byrow = TRUE,
                  dimnames = list(
                       c("dm.pde = 1", "dm.pde = 0"), # Row names 
                       c("dm.tm = 1", "dm.tm = 0")  # Column names
                 )) %>% print()

se.pde = a/(a+c)*100
sp.pde = d/(b+d)*100

#####################################################################################
#     3.    Validity of MA
#####################################################################################

# Create the 2x2 matrix
a <- dm.val %>% filter(dm.tm == 1 & dm.ma == 1) %>% count()
b <- dm.val %>% filter(dm.tm == 0 & dm.ma == 1) %>% count()
c <- dm.val %>% filter(dm.tm == 1 & dm.ma == 0) %>% count()
d <- dm.val %>% filter(dm.tm == 0 & dm.ma == 0) %>% count()

val.ma <- matrix(c(a, b, c, d), nrow = 2, byrow = TRUE,
                  dimnames = list(
                       c("dm.ma = 1", "dm.ma = 0"), # Row names 
                       c("dm.tm = 1", "dm.tm = 0")  # Column names
                 )) %>% print()

se.ma = a/(a+c)*100
sp.ma = d/(b+d)*100

#####################################################################################
#     4.    Validity of MBSF
#####################################################################################

# Create the 2x2 matrix
a <- dm.val %>% filter(dm.tm == 1 & dm.mbsf == 1) %>% count()
b <- dm.val %>% filter(dm.tm == 0 & dm.mbsf == 1) %>% count()
c <- dm.val %>% filter(dm.tm == 1 & dm.mbsf == 0) %>% count()
d <- dm.val %>% filter(dm.tm == 0 & dm.mbsf == 0) %>% count()

val.mbsf <- matrix(c(a, b, c, d), nrow = 2, byrow = TRUE,
                  dimnames = list(
                       c("dm.mbsf = 1", "dm.mbsf = 0"), # Row names 
                       c("dm.tm = 1", "dm.tm = 0")  # Column names
                 )) %>% print()

se.mbsf = a/(a+c)*100
sp.mbsf = d/(b+d)*100






