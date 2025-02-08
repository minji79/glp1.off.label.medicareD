#####################################################################################
# Project name : Identify off label use of GLP1 following several definitions
# Task Purpose : 
#       A.	The number of possible off-label GLP-1 prescriptions among GLP-1 new users from 2018 to 2020
#       B.	The number of prescriptions under utilization management among GLP-1 new users from 2018 to 2020
# Final dataset : 
#       00
#####################################################################################

setwd("/users/59883/c-mkim255-59883/glp1off/sas_input")

install.packages("MatchIt")
install.packages("cobalt")
install.packages("WeightIt")
install.packages("haven")

library(tidyverse)
library(haven)
library(lubridate)
library(dplyr)
library(ggplot2)
library(MatchIt)
library(cobalt)
library(WeightIt)
library(gridExtra)
library(grid)

# loading sas dataset
df <- read_sas("studypop.sas7bdat")


#####################################################################################
#     A.	The number of possible off-label GLP-1 prescriptions among GLP-1 new users from 2018 to 2020
#####################################################################################

# discrete time : monthly 
df <- df %>% mutate(rx_ym = format(SRVC_DT, "%Y-%m")) 

# with definition 5
glp1_all_monthly <- df %>% group_by(rx_ym) %>% summarise(glp1_count = n())
glp1_offlabel_monthly <- df %>% filter(offlabel_df5 == 1) %>% group_by(rx_ym) %>% summarise(glp1_offlabel_count = n())

monthly <- glp1_all_monthly %>% left_join(glp1_offlabel_monthly, by="rx_ym")
monthly <- monthly %>% mutate(rx_ym = as.Date(paste0(rx_ym, "-01")))

########### 1. Plot
ggplot(data = monthly, aes(x = rx_ym)) +
  geom_point(aes(y = glp1_count), size=0.5, alpha = 1, color = "blue") +
  geom_line(aes(y = glp1_count), linewidth = 0.5, linetype = "solid", color = "blue") +
  geom_point(aes(y = glp1_offlabel_count), size=0.5, alpha = 1, color = "red") +
  geom_line(aes(y = glp1_offlabel_count), linewidth = 0.5, linetype = "solid", color = "red") +
  theme_classic() +
  labs(
    x = "Month",
    y = "Number of prescriptions",
    #title = "Time trend the number of possible off-label prescriptions of GLP-1 among new users by Month"
  ) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    #plot.title = element_text(face = "bold", hjust = 0.5)
  ) + 
  scale_x_date(
    date_breaks = "1 year",   # Breaks at each year
    date_labels = "%Y"       # Show only the year
  ) +
  annotate("text", x = as.Date("2020-09-01"), y = 400, color = "red", size = 4, label = "Possibly Off-label Use") +
  annotate("text", x = as.Date("2020-09-01"), y = 3100, color = "blue", size = 4, label = "GLP1 New Users")


########## 2. absolute number summary table
table <- df %>%
  mutate(year = year(SRVC_DT)) %>% 
  group_by(year) %>%
  summarise(
    sum.count.glp1.users = n(),
    sum.count.off.label = sum(offlabel_df5 == 1, na.rm = TRUE), 
    prop.off.label = round(sum.count.off.label / sum.count.glp1.users * 100, 3)
  ) %>%
  complete(year = c(2018, 2019, 2020), fill = list(sum.count.glp1.users = 0, sum.count.off.label = 0, prop.off.label = 0))
table

# Create Summary Table for Display

summary_table <- data.frame(
  Metric = c("The total number of GLP1 Users", 
          "The number of Off-label Users", 
          "Proportion of Off-label use (%)"),
  
  "2018" = c(
    as.integer(table$sum.count.glp1.users[table$year == 2018]), 
    as.integer(table$sum.count.off.label[table$year == 2018]), 
    sprintf("%.1f", table$prop.off.label[table$year == 2018])  # Ensuring 1 decimal for proportion
  ),
  
  "2019" = c(
    as.integer(table$sum.count.glp1.users[table$year == 2019]), 
    as.integer(table$sum.count.off.label[table$year == 2019]), 
    sprintf("%.1f", table$prop.off.label[table$year == 2019])  # Ensuring 1 decimal for proportion
  ),
  
  "2020" = c(
    as.integer(table$sum.count.glp1.users[table$year == 2020]), 
    as.integer(table$sum.count.off.label[table$year == 2020]), 
    sprintf("%.1f", table$prop.off.label[table$year == 2020])  # Ensuring 1 decimal for proportion
  )
)

colnames(summary_table) <- c(" ", "FY 2018", "FY 2019", "FY 2020")

theme <- ttheme_minimal(
  core = list(
    fg_params = list(fontsize = 12, fontface = "plain", hjust = 0.5),  
    bg_params = list(fill = "white", col = "black")  
  ),
  colhead = list(
    fg_params = list(fontsize = 12, fontface = "bold", hjust = 0.5, col = "black"),  
    bg_params = list(fill = "darkgray", col = "black")  
  ),
  rowhead = list(
    fg_params = list(fontsize = 12, fontface = "bold", col = "black")  
  )
)

table_plot <- tableGrob(summary_table, theme = theme)
grid.arrange(table_plot)




#####################################################################################
#     B.	The number of prescriptions under utilization management among GLP-1 new users from 2018 to 2020
#####################################################################################

# discrete time : monthly 
df <- df %>% mutate(rx_ym = format(SRVC_DT, "%Y-%m")) 
df <- df %>% mutate(um = ifelse(PRIOR_AUTHORIZATION_YN == "1" | STEP == "1", 1, 0))

# with definition 5
glp1_all_monthly <- df %>% group_by(rx_ym) %>% summarise(glp1_count = n())
glp1_UM_monthly <- df %>% filter(um == 1) %>% group_by(rx_ym) %>% summarise(um_count=n())

monthly <- glp1_all_monthly %>% left_join(glp1_UM_monthly , by="rx_ym")
monthly <- monthly %>% mutate(rx_ym = as.Date(paste0(rx_ym, "-01")))

########### 1. Plot
ggplot(data = monthly, aes(x = rx_ym)) +
  geom_point(aes(y = glp1_count), size=0.5, alpha = 1, color = "blue") +
  geom_line(aes(y = glp1_count), linewidth = 0.5, linetype = "solid", color = "blue") +
  geom_point(aes(y = um_count), size=0.5, alpha = 1, color = "red") +
  geom_line(aes(y = um_count), linewidth = 0.5, linetype = "solid", color = "red") +
  theme_classic() +
  labs(
    x = "Month",
    y = "Number of prescriptions",
    #title = "Time trend the number of possible off-label prescriptions of GLP-1 among new users by Month"
  ) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    #plot.title = element_text(face = "bold", hjust = 0.5)
  ) + 
  scale_x_date(
    date_breaks = "1 year",   # Breaks at each year
    date_labels = "%Y"       # Show only the year
  ) +
  annotate("text", x = as.Date("2020-08-01"), y = 400, color = "red", size = 4, label = "Prescription under UM") +
  annotate("text", x = as.Date("2020-09-01"), y = 3100, color = "blue", size = 4, label = "GLP1 New Users")


########## 2. absolute number summary table
table_um <- df %>%
  mutate(year = year(SRVC_DT)) %>% 
  group_by(year) %>%
  summarise(
    sum.count.glp1.users = n(),
    sum.count.um = sum(um == 1, na.rm = TRUE), 
    prop.um = round(sum.count.um / sum.count.glp1.users * 100, 3)
  ) %>% print()




