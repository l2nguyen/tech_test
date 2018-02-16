library(httr)
library(jsonlite)
library(dplyr)

# -- Get data from API
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
wash_data <- fromJSON(content(data, as = 'text'))

# inspect data
str(wash_data)

# Take only the important part of the API
# Part 1 seems to only be information about number of obs and page
wash_data <- wash_data[[2]]

