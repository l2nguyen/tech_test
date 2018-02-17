# Visualization of sanitation data over time
This visualizes the % of population with access to improved sanitation in different countries from 1960 until now.

## Data Source
Data was retrieved from the [World Bank API](https://datahelpdesk.worldbank.org/knowledgebase/articles/898599-api-indicator-queries) using the query for a specific indicator. **Indicator code:** SH.STA.ACSN.

There are two R packages to make it easier to get data from the World Bank API: [WDI](https://github.com/vincentarelbundock/WDI) and [wbstats](https://github.com/GIST-ORNL/wbstats). But as a learning exercise, I decided to do it the harder way without using the packages.