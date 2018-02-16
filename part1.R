rm(list = ls())
# Load necessary packages
library(httr)
library(jsonlite)
library(dplyr)

#---- GET DATA FROM API ------#

# NOTE: There exists a few R packages that makes it easier to get
# data from WB API: wbstats and WDI
# Will do this the harder way for now.

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
wash_data <- fromJSON(content(data, as = 'text'), flatten = TRUE)

# inspect data
str(wash_data)

# Take only the part of the data returned from the API with the indicator data
# Part 1 seems to only be information about number of obs and page
wash_data <- wash_data[[2]]


#--- Get basic data on country
# NOTE: Mostly interested in income data
country <- GET("http://api.worldbank.org/v2/countries/",
              query = list(per_page = 2000, format = 'json'))

# Prettify nested JSON data from API
country_data <- fromJSON(content(country, "text"), flatten = TRUE)
country_data <- country_data[[2]]

#---- DATA WRANGLING ------#

# Look at the columns in the data
colnames(wash_data)

# Select only necessary columns and rename
# This also drops country level data
wash_data <- wash_data %>%
  select(1:3, indicator.id, starts_with("country.")) %>%
  rename(iso3c = countryiso3code, year = date,
         iso2c =  country.id, country = country.value) %>%
  filter(iso3c != "")

# Look at data structure
str(country_data)
colnames(country_data)
head(country_data)

# Keep only necessary columns and rename
# This also drops region level data
country_data <- country_data %>%
  filter(incomeLevel.value != "Aggregates") %>%
  select(1:3, region.id, region.value, incomeLevel.id, incomeLevel.value) %>%
  rename(iso3c = id, iso2c = iso2Code, country = name, regionID = region.id,
         region = region.value, income_code = incomeLevel.id,
         income = incomeLevel.value)

# Join the two dataset into the data we'll be working with
full_data <- left_join(x = wash_data, y = country_data, by = "iso3c")
