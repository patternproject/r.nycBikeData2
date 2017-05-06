## `````````````````````````````````````````````
#### Read Me ####
## `````````````````````````````````````````````
## Extending NYC Bike Data Analysis
## 
## http://toddwschneider.com/posts/a-tale-of-twenty-two-million-citi-bikes-analyzing-the-nyc-bike-share-system/
## 0 0 1: Basic Flow
## 0 0 2: If Else - read local data files versus download from internet
## 0 0 3: Reading Large Files via sqldf
## 0 0 4: DB Operations via DPLYR
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
pacman::p_load(sqldf)

# http://r.789695.n4.nabble.com/sqldf-for-Very-Large-Tab-Delimited-Files-td4350555.html
pacman::p_load(RSQLite)

# Now, sqldf is best used when you are getting the data from R but if 
# you want to store it in a database and just leave it there then you 
# might be better off using RSQLite directly like this (the eol = "\r\n" 
#                                                       in the dbWriteTable statement was needed on my Windows system but you 
#                                                       may not need that depending on your platform): 
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

c.home.dir = "C:/Users/burhan.haq/Downloads/Perso/23. r Practise/5. NYC Bike 2"
c.data.dir = "1.Data"
db.name = "bikeData"



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
    
    # For R Projects the working directory is always set to the root folder, 
    # so in order to load our data into R we need to first go into the “data” folder 
    # and then read in the data file, thus our call is “data/my.data.file.txt”
    
    f.name = "C:/Users/burhan.haq/Downloads/Perso/23. r Practise/5. NYC Bike 2/1.Data/201601-citibike-tripdata.csv"
    
    df.1 <- read_csv(f.name)

} # end else l.download.flag NOT SET or FALSE

# fix col names for df.1
names(df.1) = gsub(" ", "_", names(df.1))


# SQL Set-up
# https://datascienceplus.com/working-with-databases-in-r/
# http://www.datacarpentry.org/R-ecology-lesson/05-r-and-databases.html

# 1. Create a database
#db.path = "C:/Users/burhan.haq/Downloads/Perso/23. r Practise/5. NYC Bike 2/1.Data/bikeData" 
db.path = file.path(c.home.dir,c.data.dir,db.name)
my_db <- src_sqlite(path= db.path, create = TRUE) # create =TRUE creates

# 2. Put data in the database
# we have to change temporary to false to make it permanent.
bikes_sqlite <-
  copy_to(
    dest = my_db,
    df = df.1,
    temporary = FALSE,
    indexes = list("start_station_id", "gender")
  )

# remove the memory-heavy df
rm(df.1)


# 3. List the tables in the database
# https://cran.r-project.org/web/packages/dplyr/vignettes/databases.html
src_tbls(my_db)


# 4. We use tbl to connect to tables within the database.
bikeData = tbl(my_db,"df.1" )


# 5. We can see the query dplyr has generated:
query.result = filter(bikeData, start_station_id==268) 
query.result
query.result$query
explain(query.result)


# However, when working with really large CSV files, you do not want to load the
# entire file into memory first (this is the whole point of this tutorial). An
# alternative strategy is to load the data from the CSV file in chunks (small
# sections) and write them step by step to the SQlite database.

# Details here:
# SRC: https://inbo.github.io/tutorials/data-handling-large-files-R.html

## `````````````````````````````````````````````


## `````````````````````````````````````````````
#### Manipulate Data ####
## `````````````````````````````````````````````



## `````````````````````````````````````````````


## `````````````````````````````````````````````
#### Plot 1 ####
## `````````````````````````````````````````````
## `````````````````````````````````````````````


## `````````````````````````````````````````````
#### Clean up ####
## `````````````````````````````````````````````
# rm(list=ls())