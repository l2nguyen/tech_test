rm(list = ls())
# Load necessary packages
library(httr)
library(jsonlite)
library(dplyr)
library(ggplot2)

#---- GET DATA FROM API ------#

# Note: There exists a few R packages that makes it much easier to get
# data from WB API: wbstats and WDI. They transform all the code below
# into one a few lines of code.
# easy way:
# check <- WDI(country = 'all', indicator = 'SH.STA.ACSN',
# start = 1960, end = 2018, extra = TRUE, cache = NULL)
# I will do this the harder way for this exercise.

#---- Get sanitation data
api_url <- 'http://api.worldbank.org/v2/countries/all/indicators/'
indicator <- 'SH.STA.ACSN'

# Construct URL to get specific indicator
sanit_url <- paste0(api_url, indicator)

# Get data from URL
# NOTE: Per page is set very high because there are ~15300 observations
wash <- GET(sanit_url,
            query = list(per_page = 20000, date = '1960:2018', format = 'json'))

# Turn JSON API into R object
wash_data <- fromJSON(content(wash, as = 'text'), flatten = TRUE)

# inspect data
str(wash_data)

# Take only the part of the data returned from the API with the indicator data
# Part 1 seems to only be information about number of obs and page
wash_data <- wash_data[[2]]

#--- Get basic data on country
# NOTE: Mostly interested in income data
country_url <- "http://api.worldbank.org/v2/countries/"

country <- GET(country_url,
              query = list(per_page = 1000, format = 'json'))

# Prettify nested JSON data from API
country_data <- fromJSON(content(country, "text"), flatten = TRUE)
country_data <- country_data[[2]]

#---- DATA WRANGLING ------#

# Look at the columns in the sanitation data
colnames(wash_data)

wash_data <- wash_data %>%
  # Select only necessary columns
  select(1:3, indicator.id, starts_with("country.")) %>%
  # Rename columns
  rename(iso3c = countryiso3code, year = date,
         iso2c =  country.id, country = country.value) %>%
  # Drop aggregated regional data
  filter(iso3c != "")

# Check number of missing values
sum(is.na(wash_data$value))
# Note: About 50% of the data is missing a value for the sanitation indicator

missing <- wash_data %>%
  filter(is.na(value))

# Plot missing data
ggplot(data = missing, aes(x = year)) + geom_bar()
# Note: Looks like all data is missing except for 1990-2015
# Will just drop missing data for data for the purposes of this exercise

# Look at data structure
str(country_data)
colnames(country_data)
head(country_data)

# Keep only necessary columns and rename
# This also drops aggregated regional level data
country_data <- country_data %>%
  filter(incomeLevel.value != "Aggregates") %>%
  select(id, name, region.id, region.value, incomeLevel.id, incomeLevel.value) %>%
  rename(iso3c = id, country = name, regionID = region.id,
         region = region.value, income_code = incomeLevel.id,
         income = incomeLevel.value)

# Join the two dataset into the data that will be used for visualization
full_data <- wash_data %>%
  # join to country information by country code
  left_join(country_data, by = c("iso3c", "country")) %>%
  # drop observation where the indicator data is missing
  filter(!is.na(value))

#---- VISUALIZE THE DATA ------#
ggplot(data = full_data, aes(x = year, y = value, group = country, color=region)) +
  geom_line()
