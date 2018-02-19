rm(list = ls())
# Load necessary packages
x <- c("httr", "jsonlite", "dplyr", "tidyr", "ggplot2")
# install.packages(x) # warning: uncommenting this may take a number of minutes
lapply(x, library, character.only = TRUE) # load the required packages

#---- GET DATA FROM API ------#

# Note: There exists a few R packages that makes it much easier to get
# data from WB API: wbstats and WDI. They both transform all the code below
# into one a few lines of code.
# easy way:
# full_data <- WDI(country = 'all', indicator = 'SH.STA.ACSN',
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
  select(1:3, starts_with("country.")) %>%
  # Rename columns
  rename(iso3c = countryiso3code, year = date,
         iso2c =  country.id, country = country.value)

# Check number of missing values
sum(is.na(wash_data$value))
# Note: About 50% of the data is missing a value for the sanitation indicator

#--- Look at the character of missing data
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

# make df with all the aggregate data
agg_df<- wash_data %>%
  filter(iso3c == "") %>%
  filter(!is.na(value))

# Join the two dataset into the data that will be used for visualization
countries <- wash_data %>%
  # join to country information by country code
  left_join(country_data, by = c("iso3c", "country")) %>%
  # filter to only keep country data
  filter(iso3c != "") %>%
  # drop observation where the indicator data is missing
  filter(!is.na(value))

# Make data frame with the difference between 2015 and 1990 for each country
changes <- countries %>%
  # sort data
  arrange(country, year) %>%
  # group by country
  group_by(country) %>%
  # find difference between each row
  mutate(diff = c(NA, diff(value))) %>%
  group_by(country) %>%
  # add all the differences up for net change over the years in each country
  summarise(total_diff = sum(diff, na.rm = TRUE)) %>%
  # arrange by the difference
  arrange(total_diff) %>%
  left_join(country_data, by = "country")

#---- VISUALIZE THE DATA ------#
#-- Look at world data
ggplot(data = subset(agg_df, country == "World"),
       aes(x = year, y = value, group = 1)) +
  geom_point() + geom_line() +
  scale_y_continuous(breaks=seq(50, 70,by = 2)) +
  labs(x = "Year", y = "% of Population with Access", title = "Improved Sanitation Facilities (% of population with access) for the World")

#-- Look at regional data
regions <- c("Europe & Central Asia", "North America",
             "Latin America & Caribbean", "Middle East & North Africa",
             "South Asia", "East Asia & Pacific", "Sub-Saharan Africa")

ggplot(data = subset(agg_df, country %in% regions),
       aes(x = year, y = value, group = country, color = country)) +
  geom_point() + geom_line() +
  scale_y_continuous(breaks=seq(20, 100,by = 5)) +
  labs(x = "Year", y = "% of Population with Access",
       title = "Improved Sanitation Facilities (% of population with access) by Region")

# -- look at by income level
# Note: a country's income level classification can change in 1990-2015
# So we are not looking at the same country every year.
inc_levels <- c("Low income", "Lower middle income",
             "Upper middle income", "High income")

ggplot(data = subset(test, country %in% inc_levels),
       aes(x = year, y = value, group = country, color = country)) +
  geom_point() + geom_line() +
  scale_y_continuous(breaks=seq(10, 100,by = 5)) +
  labs(x = "Year", y = "% of Population with Access",
       title = "Improved Sanitation Facilities (% of population with access) by Country Income Level")

ggplot(data = subset(changes, total_diff>20),
       aes(x = reorder(country,total_diff),
           y = total_diff,
           fill = factor(region))) +
  scale_y_continuous(breaks=seq(-20, 60, by = 5)) +
  geom_bar(stat = "identity", position = "dodge") +
  coord_flip() +
  labs(x = "Country", y = "Change in % of Population with Access to Improved Sanitation",
       title = "Countries with the Largest Increase in % of Population with Access to Improved Sanitation between 1990 to 2015")
