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

# For R Projects the working directory is always set to the root folder, 
# so in order to load our data into R we need to first go into the “data” folder 
# and then read in the data file, thus our call is “data/my.data.file.txt”
URL = "https://s3.amazonaws.com/tripdata/201601-citibike-tripdata.zip"

myzip <- unz(URL, filename=basename(URL))
download.file(URL, destfile="1. Data/test.zip")
f.name = unzip("1. Data/test.zip", exdir ="1. Data")
# readr from tidyverse supports read_csv()
df.1 = read_csv(f.name,col_names = TRUE)

# remove zip file
fn <- "1. Data/test.zip"
if (file.exists(fn)) file.remove(fn)
## `````````````````````````````````````````````


## `````````````````````````````````````````````
#### Manipulate Data ####
## `````````````````````````````````````````````
str(df.1)
## `````````````````````````````````````````````


## `````````````````````````````````````````````
#### Plot 1 ####
## `````````````````````````````````````````````
## `````````````````````````````````````````````


## `````````````````````````````````````````````
#### Clean up ####
## `````````````````````````````````````````````
# rm(list=ls())