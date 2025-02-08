#####################################################################################
# Project name : 6M glp1 utilization after the first fill
# Task Purpose : 
#      1. 
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
long <- read_sas("glp1users_pde_17to20_long.sas7bdat")

#####################################################################################
#     1.    Long dataset for study population 
#####################################################################################

id <- df %>% select(BENE_ID, SRVC_DT, offlabel_df5)
id <- id %>% rename(index.date = SRVC_DT)
long <- id %>% left_join(long, by = "BENE_ID")


#####################################################################################
#     2.    6 month 
#####################################################################################

# set the 6 month period
look.forward.period = 6*30

long.summary <- long %>% 
  filter(index.date <= SRVC_DT & SRVC_DT <= index.date + look.forward.period) %>%
  group_by(BENE_ID) %>%
  summarise(
    offlabel = offlabel_df5,
    total.fill = n(),
    total.days.fill = sum(DAYS_SUPLY_NUM, na.rm = TRUE),
    payer.cost = sum(TOT_RX_CST_AMT - PTNT_PAY_AMT, na.rm = TRUE),
    oop = sum(PTNT_PAY_AMT, na.rm = TRUE)
  ) %>% ungroup()

# check missingness (need to be no missingness)
mice::md.pattern(long.summary, plot=FALSE)

# summary stat
table2 <- long.summary %>% 
  group_by(offlabel) %>%
  summarise(
    mean.total.fill = mean(total.fill),
    sd.total.fill = sd(total.fill),
    mean.total.days.fill = mean(total.days.fill),
    sd.total.days.fill = sd(total.days.fill),
    mean.payer.cost = mean(payer.cost),
    sd.payer.cost = sd(payer.cost),
    mean.oop = mean(oop),
    sd.oop = sd(oop)
  ) 
print(table2, n=Inf)

t.test(total.fill ~ offlabel, data = long.summary)
t.test(total.days.fill ~ offlabel, data = long.summary)
t.test(payer.cost ~ offlabel, data = long.summary)
t.test(oop ~ offlabel, data = long.summary)
