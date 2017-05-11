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




# df.1 = read_file(c.csv.temp.file) %>%
#   str_replace_all('"{2,3}', '"') %>%
#   read_csv(
#     col_names = TRUE,
#     col_types = cols(
#       tripduration = col_integer(),
#       starttime = col_datetime("%d/%m/%Y %H:%M"),
#       stoptime = col_skip(),
#       start station id = col_integer(),
#       start station name = col_skip(),
#       start station latitude = col_skip(),
#       start station longitude = col_skip(),
#       end station id = col_skip(),
#       end station name = col_skip(),
#       end station latitude = col_skip(),
#       end station longitude = col_skip(),
#       bikeid = col_skip(),
#       usertype = col_skip(),
#       birth year = col_skip(),
#       gender = col_skip()
#   
#     )
#   )

# nameLine <- readLines(c.csv.temp.file, n=1)

df.1 = read_file(c.csv.temp.file) %>%
  #str_replace_all('\"', '') %>%
  #str_replace_all("\\\"\\\"", "\"") %>%
  #str_replace_all("\\\"", " ") %>%
  str_replace_all('"{2,3}', '"')
  readLines(n=1)
