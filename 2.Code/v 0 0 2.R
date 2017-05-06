## `````````````````````````````````````````````
#### Read Me ####
## `````````````````````````````````````````````
## Extending NYC Bike Data Analysis
## 
## http://toddwschneider.com/posts/a-tale-of-twenty-two-million-citi-bikes-analyzing-the-nyc-bike-share-system/
## `````````````````````````````````````````````

## `````````````````````````````````````````````
#### Load Libraries ####
## `````````````````````````````````````````````
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse)
pacman::p_load(readxl)
pacman::p_load(stringr)
pacman::p_load(RCurl)

# reading large files
# SRC: http://stackoverflow.com/questions/1727772/quickly-reading-very-large-tables-as-dataframes-in-r

## `````````````````````````````````````````````

## `````````````````````````````````````````````
#### Helper Function ####
## `````````````````````````````````````````````
## `````````````````````````````````````````````

## `````````````````````````````````````````````
#### Global Settings ####
## `````````````````````````````````````````````

## ````````````````````
### Setting Working Dir
# SRC: http://stackoverflow.com/questions/17605563/efficiently-convert-backslash-to-forward-slash-in-r
# 1. At the prompt copy and paste windows path of project root folder
# x <- readline()
# 2. 
# my.dir <- gsub("\\\\", "/", x)
# 3. 
# setwd(my.dir)
# 4. check
# getwd()
## ````````````````````


## ````````````````````
### Set theme for plots
# theme_set(theme_minimal())
## `````````````````````````````````````````````


## `````````````````````````````````````````````
#### Read Data ####
## `````````````````````````````````````````````

# set to 1 if you want to download from internet
l.download.flag = 0

if(l.download.flag == 1)
{
  URL = "https://s3.amazonaws.com/tripdata/201601-citibike-tripdata.zip"
  
  myzip <- unz(URL, filename=basename(URL))
  download.file(URL, destfile="1. Data/test.zip")
  f.name = unzip("1. Data/test.zip", exdir ="1. Data")
  # readr from tidyverse supports read_csv()
  df.1 = read_csv(f.name,col_names = TRUE)
  
  # remove zip file
  fn <- "1. Data/test.zip"
  if (file.exists(fn)) file.remove(fn)
  
  # end if l.download.flag SET or TRUE
  } else {
  
    df.1 <- read_csv("C:/Users/burhan.haq/Downloads/Perso/23. r Practise/5. NYC Bike 2/1.Data/201601-citibike-tripdata.csv")

} # end else l.download.flag NOT SET or FALSE


# For R Projects the working directory is always set to the root folder, 
# so in order to load our data into R we need to first go into the “data” folder 
# and then read in the data file, thus our call is “data/my.data.file.txt”
## `````````````````````````````````````````````


## `````````````````````````````````````````````
#### Manipulate Data ####
## `````````````````````````````````````````````

# convert to tibble
df.1 <- tbl_df(df.1)

# view structure
str(df.1)
View(df.1)



## `````````````````````````````````````````````


## `````````````````````````````````````````````
#### Plot 1 ####
## `````````````````````````````````````````````
## `````````````````````````````````````````````


## `````````````````````````````````````````````
#### Clean up ####
## `````````````````````````````````````````````
# rm(list=ls())