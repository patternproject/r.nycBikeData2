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

## `````````````````````````````````````````````

# file path
c.csv.temp.file = "reduced trip data.csv"
c.csv.temp.file = file.path(c.home.dir,c.data.dir,c.csv.temp.file)

# from fn_downloadZip
df.1 = read_file(c.csv.temp.file) %>%
  str_replace_all('"{2,3}', '"') %>%
  read_csv(col_names = TRUE)

# start_time is being read in as a character
# # A tibble: 5 × 15
# tripduration         starttime          stoptime start_station_id          start_station_name start_station_latitude
# <int>             <chr>             <chr>            <int>                       <chr>                  <dbl>
#   1          288 9/1/2015 00:00:00 9/1/2015 00:04:48              263    Elizabeth St & Hester St               40.71729

## readr help
# SRC:
# http://r4ds.had.co.nz/import.html

# If these defaults don’t work for your data you can supply your own date time formats, built up of the pieces
# parse_datetime("9/1/2015 00:00:00", "%d/%m/%y %H:%M:%S")
parse_datetime("9/1/2015 00:00:00", "%d/%m/%Y %H:%M:%S")
parse_datetime("9/1/2015 02:03:04", "%d/%m/%Y %H:%M:%S")

df.1 = read_file(c.csv.temp.file) %>%
  str_replace_all('"{2,3}', '"') %>%
  #read_csv(col_names = TRUE, col_types=cols(starttime="T"("%d/%m/%Y %H:%M:%S")))
  #read_csv(col_names = TRUE, col_types=cols(starttime="T"))
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