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
## 0 0 6: Clean up (2) - insert into fails in the second iteration
## Details here: https://gist.github.com/patternproject/cc76f045464cee45e21017be6ebc0195
## 0 0 7: Clean up (3) - create a dummy table outside of purr loop. and "insert only" within the loop
## 0 0 8: Three helper functions 1) create table 2) insert into 3) files to download
## 0 0 9: Added a few TODO to be fixed later. Insert into DB requires some fixing as no check is made
##        for unique values, you can insert a row as many time as you want
## `````````````````````````````````````````````

## `````````````````````````````````````````````
#### Load Libraries ####
## `````````````````````````````````````````````
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse)
pacman::p_load(readxl)
pacman::p_load(stringr)
pacman::p_load(RCurl)
pacman::p_load(pathological) # Path Manipulation Utilities

# reading large files
# SRC: http://stackoverflow.com/questions/1727772/quickly-reading-very-large-tables-as-dataframes-in-r
pacman::p_load(sqldf)

# http://r.789695.n4.nabble.com/sqldf-for-Very-Large-Tab-Delimited-Files-td4350555.html
pacman::p_load(RSQLite)

## `````````````````````````````````````````````

## `````````````````````````````````````````````
#### Helper Function ####
## `````````````````````````````````````````````

### Description: 
## this function creates table into the data base
## should be called only once before the db is setup
### I/P: 
## None
### O/P: 
## None

fn_dbCreateTable <- function() {
  
  # downloading only a single file with reduced grid
  df <- expand.grid(m = 7, y = 2013)
  c.temp.files <- sprintf("https://s3.amazonaws.com/tripdata/%d%02d-citibike-tripdata.zip", df$y, df$m)
  URL = c.temp.files[1]

  # .csv corresponding the this .zip 
  c.csv.file = str_replace(basename(URL),".zip",".csv")
  
  # from "201307-citibike-tripdata.csv" to "2013-07 - Citi Bike trip data.csv"
  c.csv.file = paste0(substr(c.csv.file,1,4),"-",substr(c.csv.file,5,6)," ","-"," ","Citi Bike trip data.csv")

  c.csv.file = file.path(c.home.dir,c.data.dir,c.csv.file)
  
  # checking if either .csv or .zip exist
  if(file.exists(c.csv.file) || file.exists(basename(URL)))
  {
    message('file alredy exists')
    
    # 4. readr from tidyverse supports read_csv()
    df.1 = read_csv(c.csv.file,col_names = TRUE)
    
  }  else
  {
    c.zip.name = basename(URL)
    c.file.path = file.path(c.home.dir,c.data.dir,c.zip.name)
    c.data.folder = file.path(c.home.dir,c.data.dir)
    
    # SRC: http://stackoverflow.com/questions/3053833/using-r-to-download-zipped-data-file-extract-and-import-data/3053883
    # 1. Create a temp. file name (eg tempfile())
    myzip <- unz(URL, filename=basename(URL))
    
    # 2. Use download.file() to fetch the file into the temp. file
    download.file(URL, destfile=c.file.path)
    
    # 3. extract the target file from temp. file
    f.name = unzip(c.file.path, exdir=c.data.folder)
    
    # 4. readr from tidyverse supports read_csv()
    df.1 = read_csv(f.name,col_names = TRUE)
    
  } #end else
  
  # 5. fix col names for df.1
  names(df.1) = gsub(" ", "_", names(df.1))
  
  # 6. remove all but first and last rows
  df.1 <-
    df.1 %>% 
    filter(row_number() %in% c(1, n()))
  
  # 7. remove all but few cols
  df.1 <-
    df.1 %>%
    select(starttime, start_station_id, tripduration)
  
  # 8. creating db tables
  bikes_sqlite <-
     copy_to(
       dest = my_db, # remote data source
       df = df.1,# local data frame
       name = "my_table", # name for new remote table.
       temporary = FALSE, # if TRUE, will create a temporary table that is local to this connection and will be automatically deleted when the connection expires
       indexes = list("starttime", "start_station_id", "tripduration")
     )
  
  # remove zip file
  # unlink(c.zip.name)
  # TODO: Un comment the following line - for now we dont want to download again
  # file.remove(c.zip.name)
  
  # remove csv file
  # TODO: Un comment the following line - for now we dont want to download again
  # file.remove(c.csv.file)
  
  # remove temp vars
  rm(c.csv.file, myzip, URL, f.name, c.zip.name)
  rm(df, c.temp.files, c.file.path)
  

} # end fn_dbCreateTable

### Description: 
## this function insert data into the table 
## should be called only once after the db is created by 
## fn_dbCreateTable
## It is a replica of fn_dbCreateTable, except it "inserts into 
## existing table. The only difference being "db_insert_into" instead of "copy_to"
### I/P: 
## List of zip files to download and read
### O/P: 
## None

fn_downloadZip <- function(URL) {
  
  #URL = c.files[1]
  myzip <- unz(URL, filename=basename(URL))

  # warning-closing-unused-connection-n
  # SRC: 
  # http://stackoverflow.com/questions/6304073/warning-closing-unused-connection-n
  on.exit(close(URL))
  on.exit(close(myzip))
  
  # .csv corresponding the this .zip 
  c.csv.file = str_replace(basename(URL),".zip",".csv")
  
  # from "201307-citibike-tripdata.csv" to "2013-07 - Citi Bike trip data.csv"
  c.csv.file = paste0(substr(c.csv.file,1,4),"-",substr(c.csv.file,5,6)," ","-"," ","Citi Bike trip data.csv")
  
  c.csv.file = file.path(c.home.dir,c.data.dir,c.csv.file)
  
  # checking if either .csv or .zip exist
  if(file.exists(c.csv.file) || file.exists(basename(URL)))
  {
    message('file alredy exists')
    
    # 4. readr from tidyverse supports read_csv()
    df.1 = read_csv(c.csv.file,col_names = TRUE)
    
  }  else  {
    
    c.zip.name = basename(URL)
    c.file.path = file.path(c.home.dir,c.data.dir,c.zip.name)
    c.data.folder = file.path(c.home.dir,c.data.dir)
    
    # SRC: http://stackoverflow.com/questions/3053833/using-r-to-download-zipped-data-file-extract-and-import-data/3053883
    # 1. Create a temp. file name (eg tempfile())
    myzip <- unz(URL, filename=basename(URL))
    
    # 2. Use download.file() to fetch the file into the temp. file
    download.file(URL, destfile=c.file.path)
    
    # 3. extract the target file from temp. file
    f.name = unzip(c.file.path, exdir=c.data.folder)
    
    # 4. readr from tidyverse supports read_csv()
    df.1 = read_csv(f.name,col_names = TRUE)
    
  } #end else
    
  # 5. fix col names for df.1
  names(df.1) = gsub(" ", "_", names(df.1))
  
  # 6. remove all but first and last rows
  # TODO: remove this, as we want complete data, not just two rows
  df.1 <-
    df.1 %>% 
    filter(row_number() %in% c(1, n()))
  
  # 7. remove all but few cols
  df.1 <-
    df.1 %>%
    select(starttime, start_station_id, tripduration)
  
  # view the df written
  # TODO: comment this
  head(df.1)
  
  
  # TODO: Multiple Inserts of same data are happening
  # if you call this function again and again
  
  # every time after first - insert into
  # SRC: 
  # http://stackoverflow.com/questions/26568182/is-it-possible-to-insert-add-a-row-to-a-sqlite-db-table-using-dplyr-package
  
  # Use overwrite = TRUE to force overwriting of an existing table, and append =
  # TRUE to append to an existing table.
  
  db_insert_into(con = my_db$con,
                 table = "my_table",
                 values = df.1)
  
  # view the df written
  # TODO: comment this
  head(df.1)
  
  # remove the memory-heavy df
  rm(df.1)
  
  # remove temp var
  rm(myzip)
  
} # end function fn_downloadZip

### Description: 
## this function creates a list of files to download  
### I/P: 
## None
### O/P: 
## List of zip files to download and read

fn_FilesToDownload <- function(URL) {

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
  i.remove <- c (1:10)
  c.files = c.files[-i.remove]
  
  # remove temp vars
  rm(i.remove,df)
  
  return(c.files)
    
} # end FilesToDownload


### Description: 
## a function to make the column names db safe
## make names db safe: no '.' or other illegal characters,
## all lower case and unique
## SRC: 
## http://www.win-vector.com/blog/2016/02/using-postgresql-in-r/
### I/P: 
## Character Vector
### O/P: 
## Character Vector

dbSafeNames = function(names) {
  names = gsub('[^a-z0-9]+','_',tolower(names))
  names = make.names(names, unique=TRUE, allow_=TRUE)
  names = gsub('.','_',names, fixed=TRUE)
  names
}


## `````````````````````````````````````````````

## `````````````````````````````````````````````
#### Global Settings ####
## `````````````````````````````````````````````

### Setting Working Dir
## ````````````````````
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

### Global Variables
## ````````````````````
c.home.dir = "C:/Users/burhan.haq/Downloads/Perso/23. r Practise/5. NYC Bike 2"
c.output.dir = "6.Output"
c.data.dir = "1.Data"
c.db.name = "bikeData"

## SQL Set-up
# https://datascienceplus.com/working-with-databases-in-r/
# http://www.datacarpentry.org/R-ecology-lesson/05-r-and-databases.html
c.db.path = file.path(c.home.dir,c.data.dir,c.db.name)
## ````````````````````

### Set theme for plots
## ````````````````````
# theme_set(theme_minimal())
## ````````````````````

## `````````````````````````````````````````````


## `````````````````````````````````````````````
#### Read Data ####
## `````````````````````````````````````````````

## SQL Set-up
# SRC: 
# https://datascienceplus.com/working-with-databases-in-r/

## 1. Create a database

## TODO: fix how not to create a db/tables in it, if data already exists
# But before doing so
# Check if data already exists in the db
# # create is false now because I am connecting to an existing database
my_db <- src_sqlite(path= c.db.path, create = FALSE)

# List the tables in the db
src_tbls(my_db)

i.db.tables = (src_tbls(my_db)) %>% length()

if(i.db.tables > 0)
{
  message("db already exists")
  
} else{
  
  my_db <- src_sqlite(path= c.db.path, create = TRUE) # create =TRUE creates
  
  # 2. Create Tables
  fn_dbCreateTable()
  
}


# 3. List of files to download
c.files = fn_FilesToDownload()

# Insert this files into the db

c.files %>%
  map(fn_downloadZip)


# 3. List the tables in the database
# https://cran.r-project.org/web/packages/dplyr/vignettes/databases.html
src_tbls(my_db)

# 4. We use tbl to connect to tables within the database.
bikeData = tbl(my_db,"my_table" )
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

# TODO: keeping the database intact
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