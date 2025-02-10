#####################################################################################
# Project name : Identify off label use of GLP1 following several definitions
# Task Purpose : 
#      1. Preprocessing before matching (drop 349 individuals with missing age)
#      2. Simple GLM - logistic model with binary outcome (off-label use or not)
#      3.
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


#####################################################################################
#     1.    Preprocessing before Analysis (drop 349 individuals with missing age)
#####################################################################################

# 1. Preprocessing dataset
# convert in to numeric variables
df$TIER_ID <- as.numeric(df$TIER_ID)
df$STEP <- as.numeric(df$STEP)
df$QUANTITY_LIMIT_YN <- as.numeric(df$QUANTITY_LIMIT_YN)
df$PRIOR_AUTHORIZATION_YN <- as.numeric(df$PRIOR_AUTHORIZATION_YN)
df$GNDR_CD <- as.numeric(df$GNDR_CD)  # GNDR_CD == 1 -> male
df <- df %>% mutate(
  race = case_when(
    BENE_RACE_CD == 1 ~ 1,
    BENE_RACE_CD == 2 ~ 2,
    BENE_RACE_CD %in% c(0, 3, 4, 5, 6) ~ 0
  ),
  year = year(SRVC_DT),
  cvd = ifelse(acute_mi ==1 | hf == 1 | stroke ==1, 1, 0)
)

# fill NA with 0
df <- df %>%
  mutate(
        TIER_ID = ifelse(is.na(TIER_ID), 0, TIER_ID),
        STEP = ifelse(is.na(STEP), 0, STEP),
        QUANTITY_LIMIT_YN = ifelse(is.na(QUANTITY_LIMIT_YN), 0, QUANTITY_LIMIT_YN),
        PRIOR_AUTHORIZATION_YN = ifelse(is.na(PRIOR_AUTHORIZATION_YN), 0, PRIOR_AUTHORIZATION_YN),
        not_found_flag = ifelse(is.na(not_found_flag), 0, not_found_flag)
  )


# 2. change variable name and format
# treated = PRIOR_AUTHORIZATION_YN ==1 | STEP != 0
# outcome = offlabel_df5 (0/1) -> offlabel

df <- df %>% 
      mutate(
      um = ifelse(PRIOR_AUTHORIZATION_YN ==1 | STEP != 0, 1, 0)
      ) %>%
      rename(offlabel = offlabel_df5, pa = PRIOR_AUTHORIZATION_YN, step = STEP, qnt =QUANTITY_LIMIT_YN, tier = TIER_ID, uncovered_byD = not_found_flag, 
             age = age_at_index, sex = GNDR_CD, oop = PTNT_PAY_AMT, gross.rx.cost = TOT_RX_CST_AMT) 


# 3. drop 349 individuals with missing age
df <- df %>% select(-CMPND_CD, -PD_DT, -DOB_DT)
df <- df %>% filter(!is.na(age))

# 4. check missingness (need to be no missingness)
mice::md.pattern(df, plot=FALSE)


# 5. set the reference group
df$sex <- as.factor(df$sex)
df$sex <- relevel(df$sex, ref = "1") # male ==1, female ==2

df$uncovered_byD <- as.factor(df$uncovered_byD)
df$uncovered_byD <- relevel(df$uncovered_byD, ref = "0") # uncovered_byD ==1, covered ==0

df$race <- as.factor(df$race)
df$race <- relevel(df$race, ref = "1") # white ==1, black ==2, others ==3

df$tier <- as.factor(df$tier)
df$tier <- relevel(df$tier, ref = "3") # major -> 3. Brand-name drugs that don't have a generic equivalent, plus some high-priced generic drugs 


#####################################################################################
#     2.    Simple GLM - logistic model with binary outcome (off-label use or not)
#####################################################################################

model0 <- glm(offlabel ~ um + uncovered_byD + tier + year + sex + race + region + age + obesity + htn + acute_mi + hf + stroke + alzh, 
             data = df, family = binomial)
summary(model0)

# seperately 
model1 <- glm(offlabel ~ pa + step + uncovered_byD + tier + year + sex + race + region + age + obesity + htn + acute_mi + hf + stroke + alzh, 
             data = df, family = binomial)
summary(model1)

# pooling cvd
model2 <- glm(offlabel ~ um + uncovered_byD + tier + year + sex + race + region + age + obesity + htn + cvd + alzh, 
             data = df, family = binomial)
summary(model2)

# exp(Estimate) and 95%ci
coefs <- coef(summary(model2)) 
estimates <- coefs[, 1]  
std_errors <- coefs[, 2]  

z_value <- 1.96  
lower_ci <- estimates - z_value * std_errors
upper_ci <- estimates + z_value * std_errors

# Exponentiate estimates and confidence intervals
exp_estimates <- exp(estimates)
exp_lower_ci <- exp(lower_ci)
exp_upper_ci <- exp(upper_ci)

# Create a summary table
result <- data.frame(
  `aOR, Exp(Estimate)` = round(exp_estimates, 3),
  `Lower CI (95%)` = round(exp_lower_ci, 3),
  `Upper CI (95%)` = round(exp_upper_ci, 3)
)

# Print the table
print(result)

#####################################################################################
#     2.    Balance before matching
#####################################################################################

# No matching; constructing a pre-match matchit object (method=NULL)
m.out0 <- matchit(um ~ ma_16to20 + tier + sex + age_at_index + race + region_n + obesity + htn + acute_mi + hf + stroke + alzh, 
                  data = df, method = NULL, distance = "glm")

# Checking balance prior to matching
summary(m.out0)


#####################################################################################
#     3.    Propensity score matching
#####################################################################################

#Performs the matching (1:1 PS matching w/o replacement) - BENEFIT_PHASE
m.out <- matchit(um ~ ma_16to20 + tier + sex + age_at_index + race + region_n + obesity + htn + acute_mi + hf + stroke + alzh, 
                  data = df, method = "nearest") 

m.out

#Observations matched to each other (m.out$match.matrix)
head(m.out$match.matrix, 10)

#Propensity scores (m.out$distance)
m.out$distance[1:10]
summary(m.out$distance)

#Print balance summary
summary(m.out, un=FALSE)

#Summarize balance statistics in a plot (4 methods)
plot(m.out, type = "jitter", interactive = FALSE) 
plot(summary(m.out),threshold=.2)
love.plot(m.out, abs=TRUE, binary = "std", thresholds = c(m = .2),line = TRUE)
bal.plot(m.out,var.name="age_at_index",which="both")


#####################################################################################
#     4.    Caliper Matching
#####################################################################################

m.out.mahal <- matchit(pa ~ ma_16to20 + TIER_ID + STEP + age_at_index + BENE_RACE_CD + region + obesity + htn + acute_mi + hf + stroke + alzh, 
                  data = df, method = "nearest", 
                       caliper = .1,mahalvars= ~age_at_index + TIER_ID) 
summary(m.out.mahal,un=FALSE)

#Check balance
bal.tab(m.out.mahal, stats = c("m", "v", "ks"),      continuous="std",
        binary="std",
        s.d.denom = "treated")
# plot blance
love.plot(m.out.mahal,
          var.order = "unadjusted", binary = "std",
          abs = TRUE,
          line = TRUE,threshold=.2)


#####################################################################################
#     4.    Full matching -> cannot run (broken pipe)
#####################################################################################

#Note: you need to also install the optmatch package to use full matching
#install.packages("optmatch") #make sure to install the package the first time using it

m.out.full <- matchit(pa ~ ma_16to20 + TIER_ID + STEP + age_at_index + BENE_RACE_CD + region + obesity + htn + acute_mi + hf + stroke + alzh, 
                  data = df, method = "full", estimand = "ATT")

m.out.full

#####################################################################################
#     5.    Propensity Score Weighting 
#####################################################################################
#Estimate the weights
w.out <- weightit(pa ~ ma_16to20 + TIER_ID + STEP + age_at_index + BENE_RACE_CD + region + obesity + htn + acute_mi + hf + stroke + alzh, 
                  data = df, method = "ps", estimand = "ATT") 

w.out

# plot weight
plot(summary(w.out))

#Check balance
bal.tab(w.out, stats = c("m", "v", "ks"),      continuous="std",
        binary="std",
        s.d.denom = "treated")

# plot blance
love.plot(w.out,
          var.order = "unadjusted", binary = "std",
          abs = TRUE,
          line = TRUE,threshold=.2)


#####################################################################################
#     6.    Estimating the effect after matching
#####################################################################################

# 1. Extract matched dataset
matched.data <- match.data(m.out.mahal, data = df)  
nrow(matched.data)  # 7340 individuals
names(matched.data)

# 2. Preprocessing dataset

str(matched.data)
# drop variables with one level: step 
# add numeric variable for char
# race: 0 = Unknown 1 = Non-Hispanic White 2 = Black (Or African-American) 3 = Other 4 = Asian/Pacific Islander 5 = Hispanic 6 = American Indian / Alaska Native 
matched.data <- matched.data %>% 
      mutate(
        region_n = case_when(
          region == "Midwest" ~ 1,
          region == "Northeast" ~ 2,
          region == "South" ~ 3,
          region == "West" ~ 4,
          TRUE ~ NA_real_  
        )
      )

# Convert categorical variables to factors & numerics
cols_to_factor <- c("offlabel", "pa", "ma_16to20", "TIER_ID", "BENE_RACE_CD", "region", "obesity", "htn", "acute_mi", "hf", "stroke", "alzh")
matched.data[cols_to_factor] <- lapply(matched.data[cols_to_factor], as.factor)
matched.data[cols_to_factor] <- lapply(matched.data[cols_to_factor], as.numeric)


# 3. Outcome model (difference in means; like a t-test but done using linear regression with no predictors besides treatment status)
model1 <- glm(offlabel ~ pa, data = matched.data, weights = weights)
coeftest(model1, vcov. = vcovCL, cluster = ~subclass)


# 4. Do regression adjustment on the matched samples
#options(scipen = 999)
#options(scipen = 0)
model2 <- glm(offlabel ~ pa + ma_16to20 + TIER_ID + BENE_RACE_CD + region + age_at_index + obesity + htn + acute_mi + hf + stroke + alzh, 
             data = matched.data, weights = weights)

coeftest(model2, vcov. = vcovCL, cluster = ~subclass)


# exp(Estimate) and 95%ci
coefs <- coeftest(model2, vcov. = vcovCL, cluster = ~subclass)
estimates <- coefs[, 1]  
std_errors <- coefs[, 2]  

z_value <- 1.96  
lower_ci <- estimates - z_value * std_errors
upper_ci <- estimates + z_value * std_errors

# Exponentiate estimates and confidence intervals
exp_estimates <- exp(estimates)
exp_lower_ci <- exp(lower_ci)
exp_upper_ci <- exp(upper_ci)

# Create a summary table
result <- data.frame(
  Estimate = estimates,
  `Exp(Estimate)` = exp_estimates,
  `Lower CI (95%)` = exp_lower_ci,
  `Upper CI (95%)` = exp_upper_ci
)

# Print the table
print(result)

# 5. Marginal effect
comp <- comparisons(model2,
                     variables = "pa",
                     vcov = ~subclass,
                     newdata = subset(matched.data, pa == 1),
                     wts = "weights")
summary(comp)
