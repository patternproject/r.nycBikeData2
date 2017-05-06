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
## 0 0 5: Clean up 
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

# for Kable (Df View)
pacman::p_load(knitr)

## `````````````````````````````````````````````

## `````````````````````````````````````````````
#### Helper Function ####
## `````````````````````````````````````````````
fn_downloadZip <- function(URL) {
  
  #URL = c.files
  myzip <- unz(URL, filename=basename(URL))
  c.zip.name = "test.zip"
  c.file.path = file.path(c.home.dir,c.data.dir,c.zip.name)
  c.data.folder = file.path(c.home.dir,c.data.dir)
  download.file(URL, destfile=c.file.path)
  f.name = unzip(c.file.path, exdir=c.data.folder)
  
  # readr from tidyverse supports read_csv()
  df.1 = read_csv(f.name,col_names = TRUE)
  
  # remove zip file
  if (file.exists(c.file.path)) file.remove(c.file.path)
  
  # fix col names for df.1
  names(df.1) = gsub(" ", "_", names(df.1))
  
  ## 2. Put data in the database - HAPPENS HERE
  bikes_sqlite <-
    copy_to(
      dest = my_db,
      df = df.1,
      temporary = FALSE,
      indexes = list("start_station_id", "gender"),
      append = TRUE
    )

  # remove the memory-heavy df
  rm(df.1)
  
  # remove temp var
  rm(myzip)
  
  
} # end function 
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
c.db.name = "bikeData"

# set to 1 if you want to download from internet
l.download.flag = 1

## ````````````````````


## ````````````````````
### Set theme for plots
# theme_set(theme_minimal())
## `````````````````````````````````````````````


## `````````````````````````````````````````````
#### Read Data ####
## `````````````````````````````````````````````

### SQL Set-up
# https://datascienceplus.com/working-with-databases-in-r/
# http://www.datacarpentry.org/R-ecology-lesson/05-r-and-databases.html

## 1. Create a database
#db.path = "C:/Users/burhan.haq/Downloads/Perso/23. r Practise/5. NYC Bike 2/1.Data/bikeData" 
c.db.path = file.path(c.home.dir,c.data.dir,c.db.name)
my_db <- src_sqlite(path= c.db.path, create = TRUE) # create =TRUE creates

## 2. Put data in the database
# this now happens inside the helper fn
# fn_downloadZip



### Create a matrix or combo of all files to be downloaded
# SRC: 
# https://gist.github.com/patternproject/0a7ade8fa3d85453076d9bafc2087127

## Method 1 (Preferred due to clarity of output)
# df <- expand.grid(m = 1:12, y = 2013:2017)
# c.files <- sprintf("https://s3.amazonaws.com/tripdata/%d%02d-citibike-tripdata.zip", df$y, df$m)

# for Testing reducing the c.files
df <- expand.grid(m = 1:12, y = 2013)
c.files <- sprintf("https://s3.amazonaws.com/tripdata/%d%02d-citibike-tripdata.zip", df$y, df$m)


## Method 2
# url <- "https://s3.amazonaws.com/data/%d%02d.csv.zip"
# d <- cross2(2015:2016, 1:12)
# map_chr(d, ~ sprintf(url, .[[1]], .[[2]]))

## Method 3 (Preferred due to clarity)
# https://groups.google.com/forum/#!topic/manipulatr/rB0PtGGZQDg

# i.years <- 2013L:2017L 
# c.months <- str_pad(1:12,2,pad="0") 
# str_c("https://s3.amazonaws.com/tripdata/", i.years, rep(c.months, length(i.years)), "-citibike-tripdata.zip") 
### - matrix code ENDS

## Remove file names that do not exist
# # 2013: 01 to 06
# i.remove <- c (1:6)
# # 2014: None
# # 2015: None
# # 2016: None
# # 2017: 04 to 12
# i.remove <- c (i.remove,52:60)
# # updating file vector
# c.files = c.files[-i.remove]
# # removing temp var
# rm(df, i.remove)

# for Testing reducing the c.files
# 2013: 01 to 10
i.remove <- c (1:11)
c.files = c.files[-i.remove]

# remove temp vars
rm(i.remove,df)


if(l.download.flag == 1)
{
  c.files %>%
  map(fn_downloadZip)
  
  # end if l.download.flag SET or TRUE
  } else {
    
    # For R Projects the working directory is always set to the root folder, 
    # so in order to load our data into R we need to first go into the “data” folder 
    # and then read in the data file, thus our call is “data/my.data.file.txt”
    
    f.name = "C:/Users/burhan.haq/Downloads/Perso/23. r Practise/5. NYC Bike 2/1.Data/201601-citibike-tripdata.csv"
    
    df.1 <- read_csv(f.name)

} # end else l.download.flag NOT SET or FALSE


# 3. List the tables in the database
# https://cran.r-project.org/web/packages/dplyr/vignettes/databases.html
src_tbls(my_db)

# 4. We use tbl to connect to tables within the database.
bikeData = tbl(my_db,"df.1" )
head(bikeData)

# memory intensive - use with care
View(bikeData)
# kable(bikeData)

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

# 6. Closing Connection
# SRC: 
# http://stackoverflow.com/questions/26331201/disconnecting-src-tbls-connection-in-dplyr
dbDisconnect(my_db$con)
rm(bikeData)
rm(bikes_sqlite)

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