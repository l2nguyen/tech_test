# Technical Exercise

## Guide
**Part 1**
The R markdown script can be found [here](part1.rmd).
The output can be found [here](https://l2nguyen.shinyapps.io/sanitation/){:target="_blank"}.

**Part 2**
The write up can be found [here](part2.md).

## Details for Part 1
This visualizes the % of population with access to improved sanitation in different countries from 1960 until now. Even though we were asked to pull data from 1960 until now, data was only available from 1990-2015, so that visualization only visualizes those years.

### Data Source
Data was retrieved from the [World Bank API](https://datahelpdesk.worldbank.org/knowledgebase/articles/898599-api-indicator-queries) using the query for a specific indicator. **Indicator code:** SH.STA.ACSN.

There are two R packages that make it easier to get data from the World Bank API: [WDI](https://github.com/vincentarelbundock/WDI) and [wbstats](https://github.com/GIST-ORNL/wbstats). But as a learning exercise, I decided to do it the harder way without using the packages.
