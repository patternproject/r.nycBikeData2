## `````````````````````````````````````````````
#### Read Me ####
## `````````````````````````````````````````````

# From the following line in csv 
#   starttime start_station_id tripduration
# 1  8/1/2016 00:01:22              302          288

# The start_time field is populated as "8" 
# 8 302 288

# This file is debugging it, where reduced trip data.csv 
# is a reduced 3 line input

# v 3: Refer to fn_downloadZip output v3 where the difference between these four problematic files
#      is explained in detail. In this version lets try to fix it. 
#      a) moved all details related to 201409 section to 201409 Data Debug Section
#      b) similarly for 201501 (it is similar for all four) 
#      This file needs definitions from v 0 5 such as c.home.dir and helper functions

# v 4: Copying a subset from sublime to excel was messing up the reduced data set
#      Tried some strange things in v3. Cleaning it up in v4

# v 5: Output of "201409" in fn_downloadZip output v4 has missing values - refer to 201409 Data Debug 2 Section

# R Pointers
# https://cran.r-project.org/doc/contrib/de_Jonge+van_der_Loo-Introduction_to_data_cleaning_with_R.pdf
# https://github.com/datacamp/courses-readr/blob/master/chapter1.Rmd


## `````````````````````````````````````````````

#### 201409 Data Debug  ####

## file name for the reduced data set
# a. For 201409 Data
# reduced trip data.csv was based on: "https://s3.amazonaws.com/tripdata/201409-citibike-tripdata.zip"
# open it in sublime and copy top few rows
c.csv.temp.file = "reduced trip data.csv"

## building the file path
c.csv.temp.file = file.path(c.home.dir,c.data.dir,c.csv.temp.file)

# from fn_downloadZip
df.1 = read_file(c.csv.temp.file) %>%
  str_replace_all('"{2,3}', '"') %>%
  read_csv(col_names = TRUE)


## --> start_time is being read in as a character for 201409 Data
# following section is the debug section for it
# # A tibble: 5 × 15
# tripduration         starttime          stoptime start_station_id          start_station_name start_station_latitude
# <int>             <chr>             <chr>            <int>                       <chr>                  <dbl>
#   1          288 9/1/2015 00:00:00 9/1/2015 00:04:48              263    Elizabeth St & Hester St               40.71729

# which is a problem in some cases. Read it instead as a datetime col

## readr help
# SRC:
# http://r4ds.had.co.nz/import.html

# If these defaults don’t work for your data you can supply your own date time formats, built up of the pieces
# parse_datetime("9/1/2015 00:00:00", "%d/%m/%y %H:%M:%S")
parse_datetime("9/1/2015 00:00:00", "%d/%m/%Y %H:%M:%S")
parse_datetime("9/1/2015 02:03:04", "%d/%m/%Y %H:%M:%S")

df.1 = read_file(c.csv.temp.file) %>%
  str_replace_all('"{2,3}', '"') %>%
  read_csv(col_names = TRUE, col_types=cols(starttime=col_datetime("%d/%m/%Y %H:%M:%S")))
  # this read_csv is the magical line that needs to go back to v 0 4


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
#cat("head(df.1)", head(df.1))
print.data.frame(head(df.1))



#### 201501 Data Debug  ####
# b. For 201501 Data
# reduced trip data.csv was based on: "https://s3.amazonaws.com/tripdata/201501-citibike-tripdata.zip"
# open it in sublime and copy top few rows
#c.csv.temp.file = "reduced trip data - 201501.csv" # copied and saved in excel
c.csv.temp.file = "reduced trip data - 201501 - 2.csv" # directly saved in sublime
# same strange thing was happening in copying from sublime to excel. 
# compare "reduced trip data - 201501.csv" to ""reduced trip data - 201501 - 2.csv"
# will clean up the mess in next version - which did not work


# c. For 201502 Data
# reduced trip data.csv was based on: "https://s3.amazonaws.com/tripdata/201502-citibike-tripdata.zip"
# open it in sublime and copy top few rows
#c.csv.temp.file = "reduced trip data - 201502.csv"

# d. For 201503 Data
# reduced trip data.csv was based on: "https://s3.amazonaws.com/tripdata/201503-citibike-tripdata.zip"
# open it in sublime and copy top few rows
#c.csv.temp.file = "reduced trip data - 201503.csv"

# e. For 201506 Data
# reduced trip data.csv was based on: "https://s3.amazonaws.com/tripdata/201506-citibike-tripdata.zip"
# open it in sublime and copy top few rows
#c.csv.temp.file = "reduced trip data - 201506.csv"

## building the file path
c.csv.temp.file = file.path(c.home.dir,c.data.dir,c.csv.temp.file)

## ISSUE: the start_time does not have second part (refer to fn_downloadZip output v3)

## readr help
# SRC:
# http://r4ds.had.co.nz/import.html

# If these defaults don’t work for your data you can supply your own date time formats, built up of the pieces
c.temp = "1/1/2015 0:01"
#c.temp = "6/1/2015 0:13"
parse_datetime(c.temp, "%d/%m/%Y %H:%M")


# from fn_downloadZip
df.1 = read_file(c.csv.temp.file) %>%
  str_replace_all('"{2,3}', '"') %>%
  read_csv(col_names = TRUE)

df.temp = read_file(c.csv.temp.file) %>%
  str_replace_all('"{2,3}', '"') %>%
  read_csv(col_names = TRUE, col_types=cols(starttime=col_datetime("%d/%m/%Y %H:%M")))

df.temp == df.1 # which says everything equal except starttime

# lets use the col_datetime modified for this case
# hence our magical line in this case
read_csv(col_names = TRUE, col_types=cols(starttime=col_datetime("%d/%m/%Y %H:%M")))
# notice there is no second part here, which is there for all other files

#### 201409 Data Debug 2 ####


# ----entering fn_downloadZip 
# processing file:  https://s3.amazonaws.com/tripdata/201409-citibike-tripdata.zip
# 
# entering if else block for normal .csv files
# normal means the file name is not expanded. Quote Issues or DateTime issues still there
# corresponding csv file:  C:/Users/burhan.haq/Downloads/Perso/23. r Practise/5. NYC Bike 2/1.Data/201409-citibike-tripdata.csv
# file already exists
# 
# entering nested else block for normal .csv files - 
#   these have second in start time field, along with quotes in col name and data
# |=========================================================================================================| 100%  175 MB
# Warning: 755248 parsing failures.
# row        col           expected     actual         file
# 8 birth year delimiter or quote 0          literal data
# 8 NA         15 columns         14 columns literal data
# 15 birth year delimiter or quote 0          literal data
# 15 NA         15 columns         14 columns literal data
# 26 birth year delimiter or quote 0          literal data
# ... .......... .................. .......... ............
# See problems(...) for more details.
# 
# starttime start_station_id tripduration
# 1 2014-01-09 00:00:25              386         2828
# 2                <NA>              147          978

# Why does the second entry have missing starttime

# lets check the data file

# First Entry
# "2828","9/1/2014 00:00:25","9/1/2014 00:47:33","386","Centre St & Worth St","40.71494807","-74.00234482","450","W 49 St & 8 Ave","40.76227205","-73.98788205","15941","Subscriber","1980","1"

# Last Entry
# "978","9/30/2014 23:59:59","10/1/2014 00:16:17","147","Greenwich St & Warren St","40.71542197","-74.01121978","116","W 17 St & 8 Ave","40.74177603","-74.00149746","15068","Subscriber","1992","1"

c.temp = "9/30/2014 23:59:59"
parse_datetime(c.temp, "%d/%m/%Y %H:%M:%S")
parse_datetime(c.temp, "%m/%d/%Y %H:%M:%S")
#parse_datetime(c.temp, "%1m/%d/%Y %H:%M")

c.temp = "9/25/2014 21:59:58"
parse_datetime(c.temp, "%m/%d/%Y %H:%M:%S")


# skip cols in read command -----------------------------------------------

# col_skip Skip a column
# Description
# Use this function to ignore a column when reading in a file. To skip all columns not otherwise
# specified, use cols_only().

# cols_only() allows you to load only the specified columns:
#   
#   read_csv("a,b,c\n1,2,3", col_types = cols_only("b" = "?"))

df.temp = read_file(c.csv.temp.file) %>%
  str_replace_all('"{2,3}', '"') %>%
  read_csv(col_names = TRUE,
           col_types = cols_only(tripduration = col_integer(), 
                                 starttime = col_datetime("%d/%m/%Y %H:%M"),
                                 "start station id" = col_integer()))



