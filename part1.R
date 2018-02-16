# SET UP ----------------------------------
library(httr)
library(jsonlite)
library(dplyr)
library(wbstats)

# GET DATA FROM API ----------------------------------
# NOTE: There exists a few R packages that makes it easier to get
# data from WB API: wbstats and WDI
# Will do this the harder way for now.

api_url <- 'http://api.worldbank.org/v2/countries/all/indicators/'
indicator <- 'SH.STA.ACSN'

# Construct URL to get specific indicator
sanit_url <- paste0(api_url, indicator)

# Get data from URL
# NOTE: Per page is set very high because there are ~15300 observations
data <- GET(sanit_url,
             query = list(per_page = 20000, date = '1960:2018', extra = 'TRUE',
                          format = 'json'))

# Turn JSON API into R object
wash_data <- fromJSON(content(data, as = 'text'), flatten = TRUE)

# inspect data
str(wash_data)

# Take only the part of the data returned from the API with the indicator data
# Part 1 seems to only be information about number of obs and page
wash_data <- wash_data[[2]]

# Look at the columns in the data
colnames(wash_data)

# Select only necessary columns and rename
wash_data <- wash_data %>%
  select(1:3, indicator.id, starts_with("country.")) %>%
  rename(iso3c = countryiso3code, iso2c =  country.id, country = country.value) %>%
  filter(iso3c != "")
