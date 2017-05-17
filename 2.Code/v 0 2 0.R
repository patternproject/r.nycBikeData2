## `````````````````````````````````````````````
#### Read Me ####
## `````````````````````````````````````````````
## Extending NYC Bike Data Analysis
## SRC:
## http://toddwschneider.com/posts/a-tale-of-twenty-two-million-citi-bikes-analyzing-the-nyc-bike-share-system/

## 0 0 1: Basic Flow

## 0 0 2: If Else - read local data files versus download from internet

## 0 0 3: Reading Large Files via sqldf

## 0 0 4: DB Operations via DPLYR

## 0 0 5: Clean up

## 0 0 6: Clean up (2) - insert into fails in the second iteration
##        Details here: https://gist.github.com/patternproject/cc76f045464cee45e21017be6ebc0195

## 0 0 7: Clean up (3) - create a dummy table outside of purr loop. and "insert only" within the loop

## 0 0 8: Three helper functions 1) create table 2) insert into 3) files to download

## 0 0 9: a) Added a few TODO to be fixed later.
##        b) Insert into DB requires some fixing as no check is made
##        for unique values, you can insert a row as many time as you want

## 0 1 0: a) DPLYR DB Functions do not allow putting "Unique" or "Key" Constraints. It can be
##        done manually as mentioned here
##        SRC:
##        http://stackoverflow.com/questions/29541139/upsert-data-table-into-sql-database/29541538#29541538
##        But more simpler approach is to use "unique" after all insertions
##        b) Moved db connection to "Clean Up" Section

## 0 1 0: (Rev 2) Cleaned up "Read Me" by adding a) and b) if a particular version had more than one changes

## 0 1 1: a) First build the analysis, then get the complete dataset. This version builds the basic analysis part
##        b) Dplyr SQL Interface returns "tbl_sqlite" which has restrictions on what we can do with it. Shifting to plain SQL
##        returns a"r data frame" removing all restrictions of SQLLITE (such as Lack of support for Window Options)

## 0 1 2: a) Updating c.files with actual required csv files from Aug 2014 to Aug 2016 in fn_FilesToDownload
##        b) CSV -> SQLITE DB loop works, except that starttime col has some issues with few entries

## 0 1 3: a) fn_downloadZip modified as csv files within zip can either be normal or expanded.
##        b) read_csv failing as the input files starting from "https://s3.amazonaws.com/tripdata/201409-citibike-tripdata.zip
##           have a strange format. Both col names and data are quoted. Search for "START FROM HERE" to find the error location

## 0 1 4: a) fn_downloadZip modified look for comment "# somehow files after". All files except "https://s3.amazonaws.com/tripdata/201408-citibike-tripdata.zip"
##           onwards have a strange syntax where each of col names and data are wrapped in ""
##           hence we check if file name has 201408 and read it normally or do an extra step to remove quotes
##        b) file "reduce data v1.R" is a debug attempt for a)
##        c) Even after a) there are still warnings need to see if any of them relate to "start time", as there are a lot of NA values

## 0 1 5: a) Nothing changed from 0 1 4 yet, except read me
##        b) reduce data v2 begins to look at problematic files still for start time
##        c) fn_downloadZip output v2. all other diagnostic messages removed, except where start time was mentioned as parsing error

## 0 1 6: a) Copying updated fn_downloadZip from fn_downloadZip v 1.R
##        Refer to its readme for details
##        b) col_datetime("%d/%m/%Y %H:%M") should have been col_datetime("%m/%d/%Y %H:%M")
##        order of d and m changed (first two parms)
##        c) reducing the cols read by cols_only to ramp up the speed.
##        d) write csv "df.master" to hv the sql output. Will hv to see is size allows this later

## 0 1 7: a) v 0 1 6  completes the basic loop of reading all csv files (regardless of their differences)
##        but it reads or limits it self to two rows for testing the reading loop. This is an attempt to read in more data
##        lets gradually move to more rows per csv file. 
##        b) Added fn_append_to_sqlite for chunk processing

## 0 1 8: a) As per read chunked v 2
##        fn_append_to_sqlite() was throwing error:
##        Error in filter_impl(.data, dots) : 
##        SET_VECTOR_ELT() can only be applied to a 'list', not a 'symbol'
## 
##        for this line:
##        > x %>%
##        +     filter(row_number() %in% c(1, n()))
## 
##        change the code to use slice instead
##        b) The above error now shifts to select statement in 
##        fn_dbCreateTable. Made the following change in fn_dbCreateTable
##            #slice(1:n()) -> effectively the entire df
##        slice(c(1,n()))
##        b) fn_downloadZip
##        had to replace the following in read_csv_chunked call
##              #callback = fn_append_to_sqlite(),
##              callback = fn_append_to_sqlite,
##              now bracket following the function name --> Important
##        c) fn_append_to_sqlite
##        table parameter is called name and not table
##        hence the following change
##        dbWriteTable(con = my_db$con, 
##        table = table_name, 
##        name = "my_table", 
##        value = x, 
##        append = TRUE)
##        d) added global var i.chunk_size = 10
##        e) Now - read_csv_chunked reads in a chunk of <i.chunk_size>
##        then gets the top and bottom row and inserts in the db
##        f) remember to clean up before saving r.Data on exit

## 0 1 9: a) reduced diagnostic messages in fn_append_to_sqlite
##        b) changed global var i.chunk_size from 10 to 1000

## 0 2 0: a) changing fn_download
##        c.files %>% map(fn_downloadZip)
##        to use c.files from c.files = c.files[1:3] to c.files
##        b) removing slice command, i.e. for each csv file 
##        no more top and bottom rows. but all rows
##         x <-
##           x %>%
##           #filter(row_number() %in% c(1, n()))
##           #slice(1:n()) -> effectively the entire df
##             slice(c(1,n()))
##        c) read loop finishes without any error. But records inserted are only 48K

## R DB Pointers
# 1. https://datascienceplus.com/working-with-databases-in-r/
# (Highly Useful)
# 2. http://www.utsc.utoronto.ca/~butler/climate-lab/climate-lab.html#/32
# (Highly Useful)

# 3. http://www.fightprior.com/2016/08/11/Building_mySQL_fight_db/
# 4. https://scottishsnow.wordpress.com/2014/08/14/writing-to-a-database-r-and-sqlite/
# 4. https://www.r-bloggers.com/r-and-sqlite-part-1/
# 4. https://bioconductor.org/packages/devel/bioc/vignettes/Organism.dplyr/inst/doc/Organism.dplyr.html
# 5. http://csjp.users.sonic.net/SEQUELFun.html
# 6. https://renkun.me/blog/2014/02/07/use-sql-to-operate-r-data-frames.html

## R DPLYR Pointers
# 1. https://csgillespie.github.io/efficientR/data-carpentry.html
# 2. http://www.aridhia.com/technical-tutorials/introduction-to-dplyr/
# 3. https://www.linkedin.com/pulse/r-data-wrangling-dplyr-tutorial-50-samples-michiel-victor
# 4. http://www.listendata.com/2016/08/dplyr-tutorial.html

## R Regular Expressions
# 1. http://stringr.tidyverse.org/articles/regular-expressions.html#alternation


## NOTES

## Create database one time from all csv files.
## Focus more on analysis then automating "reading files" into the database
## One could avoid "fn_dbCreateTable" and simply use a SQL statement
## SRC:
##
# dbSendQuery(conn=db,
#             "CREATE TABLE SSGB_obs
#             (Date DATETIME,
#             Station TEXT,
#             Snowline TEXT,
#             PRIMARY KEY (Date, Station))
#             ")
## We have a primary key constraint here, avoiding our multiple insertion issue
## Yes the table structure will be "hard coded" but lets overlook it for now
## "Read Data" should not download but read from an already created data set

## `````````````````````````````````````````````

## `````````````````````````````````````````````
#### Load Libraries ####
## `````````````````````````````````````````````
if (!require("pacman"))
  install.packages("pacman")
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
  c.temp.files <-
    sprintf("https://s3.amazonaws.com/tripdata/%d%02d-citibike-tripdata.zip",
            df$y,
            df$m)
  URL = c.temp.files[1]
  
  # .csv corresponding the this .zip
  c.csv.file = str_replace(basename(URL), ".zip", ".csv")
  
  # from "201307-citibike-tripdata.csv" to "2013-07 - Citi Bike trip data.csv"
  c.csv.file = paste0(
    substr(c.csv.file, 1, 4),
    "-",
    substr(c.csv.file, 5, 6),
    " ",
    "-",
    " ",
    "Citi Bike trip data.csv"
  )
  
  c.csv.file = file.path(c.home.dir, c.data.dir, c.csv.file)
  
  # checking if either .csv or .zip exist
  if (file.exists(c.csv.file) || file.exists(basename(URL)))
  {
    message('file alredy exists')
    
    # 4. readr from tidyverse supports read_csv()
    df.1 = read_csv(c.csv.file, col_names = TRUE)
    
    # warning-closing-unused-connection-n
    # SRC:
    # http://stackoverflow.com/questions/6304073/warning-closing-unused-connection-n
    #on.exit(close(URL))
    #on.exit(close(myzip))
    
    
  }  else
  {
    c.zip.name = basename(URL)
    c.file.path = file.path(c.home.dir, c.data.dir, c.zip.name)
    c.data.folder = file.path(c.home.dir, c.data.dir)
    
    # SRC: http://stackoverflow.com/questions/3053833/using-r-to-download-zipped-data-file-extract-and-import-data/3053883
    # 1. Create a temp. file name (eg tempfile())
    myzip <- unz(URL, filename = basename(URL))
    
    # 2. Use download.file() to fetch the file into the temp. file
    download.file(URL, destfile = c.file.path)
    
    # 3. extract the target file from temp. file
    f.name = unzip(c.file.path, exdir = c.data.folder)
    
    # 4. readr from tidyverse supports read_csv()
    df.1 = read_csv(f.name, col_names = TRUE)
    
  } #end else
  
  # 5. fix col names for df.1
  names(df.1) = gsub(" ", "_", names(df.1))
  
  # 6. remove all but first and last rows
  df.1 <-
    df.1 %>%
    #filter(row_number() %in% c(1, n()))
    #slice(1:n()) -> effectively the entire df
    slice(c(1,n()))
  
  # 7. remove all but few cols
  df.1 <-
    df.1 %>%
    select(starttime, start_station_id, tripduration)
  
  # 8. creating db tables
  bikes_sqlite <-
    copy_to(
      dest = my_db,
      # remote data source
      df = df.1,
      # local data frame
      name = "my_table",
      # name for new remote table.
      temporary = FALSE,
      # if TRUE, will create a temporary table that is local to this connection and will be automatically deleted when the connection expires
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
  # rm(c.csv.file, myzip, URL, f.name, c.zip.name)
  rm(c.csv.file, URL)
  # rm(df, c.temp.files, c.file.path)
  rm(df, c.temp.files)
  
  
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
  URL = c.files[1]
  myzip <- unz(URL, filename = basename(URL))
  
  ## Diagnostic Messages
  cat("\n ----")
  cat("entering fn_downloadZip \n")
  cat("processing file: ", URL)
  cat("\n")
  
  ## warning-closing-unused-connection-n
  # does NOT work, commenting out
  # SRC:
  # http://stackoverflow.com/questions/6304073/warning-closing-unused-connection-n
  # on.exit(close(URL))
  # on.exit(close(myzip))
  
  # .csv corresponding the this .zip
  c.csv.file = str_replace(basename(URL), ".zip", ".csv")
  
  ## it can either be in extended form or normal form
  # normal form: 201307-citibike-tripdata.csv
  # extended form: 2013-07 - Citi Bike trip data.csv
  # from "201307-citibike-tripdata.csv" to "2013-07 - Citi Bike trip data.csv"
  c.csv.file.ext = paste0(
    substr(c.csv.file, 1, 4),
    "-",
    substr(c.csv.file, 5, 6),
    " ",
    "-",
    " ",
    "Citi Bike trip data.csv"
  )
  
  ## file paths for both normal and extended forms
  c.csv.file.ext = file.path(c.home.dir, c.data.dir, c.csv.file.ext)
  c.csv.file = file.path(c.home.dir, c.data.dir, c.csv.file)
  
  ## if BLOCK
  # checking if either extended .csv or .zip exist
  if (file.exists(c.csv.file.ext) || file.exists(basename(URL)))
  {
    cat("corresponding extended csv file: ", c.csv.file.ext)
    message('file already exists')
    
    # 4. readr from tidyverse supports read_csv()
    # moving from read_csv to read_csv_chunked
    #df.1 = read_csv(c.csv.file.ext, col_names = TRUE)
    read_csv_chunked(
      file = c.csv.file.ext,
      #callback = fn_append_to_sqlite(),
      callback = fn_append_to_sqlite,
      chunk_size = i.chunk_size,
      col_names = TRUE,
      progress = TRUE
    )
    
    
    # TODO: above read.csv might need fixing, but few only one csv file
    # has the extended name format
    
  } else if (file.exists(c.csv.file))
  {
    # else if BLOCK, for normal .csv file
    
    # normal means the file name is not expanded.
    # Quote Issues or DateTime issues are still there and are
    # handled by inner if-elseif-else blocks
    # first if: 201408
    # else if: 2015 files
    # else: all other files
    
    cat("\n entering if else block for normal .csv files")
    cat(
      "\n normal means the file name is not expanded. Quote Issues or DateTime issues still there"
    )
    cat("\n corresponding csv file: ", c.csv.file)
    cat("\n")
    message('file already exists')
    
    # somehow files after (08)
    # "https://s3.amazonaws.com/tripdata/201408-citibike-tripdata.zip"
    # i.e.(09, 10, ...)
    # "https://s3.amazonaws.com/tripdata/201409-citibike-tripdata.zip"
    # onwards have a strange syntax
    # where each of col names and data are wrapped in ""
    # hence we check if file name has 201408
    if (str_detect(c.csv.file, "201408"))
    {
      # nested if BLOCK, for normal .csv file
      # special handling for 201408 data file
      
      cat(
        "\n entering nested if block for normal .csv files - special handling for data file: 201408 "
      )
      cat("\n")
      
      # 4. readr from tidyverse supports read_csv()
      # moving from read_csv to read_csv_chunked
      # df.1 = read_csv(c.csv.file, col_names = TRUE)
      read_csv_chunked(
        file = c.csv.file,
        callback = fn_append_to_sqlite("my_table"),
        col_names = TRUE,
        progress = TRUE
      )
      
    } else if (str_detect(c.csv.file, "201501|201502|201503|201506"))
    {
      # nested if else BLOCK, for normal .csv file
      # special handling for four data files,
      # namely: 201501, 201502, 201503 and 201506
      # Refer to fn_downloadZip output v3 for details
      
      cat(
        "\n entering nested if block for normal .csv files - special handling for data file: 201501,201502,201503,201506"
      )
      cat("\n these have missing second in start time field")
      cat("\n")
      
      # 4. readr from tidyverse supports read_csv()
      # but first remove the quotes
      # df.1 = read_file(c.csv.file) %>%
      #   str_replace_all('"{2,3}', '"') %>%
      #   read_csv(col_names = TRUE,
      #            col_types = cols(starttime = col_datetime("%m/%d/%Y %H:%M")))
      
      # moving from read_csv to read_csv_chunked
      # df.1 = read_file(c.csv.file) %>%
      #   str_replace_all('"{2,3}', '"') %>%
      #   read_csv(
      #     col_names = TRUE,
      #     col_types = cols_only(
      #       tripduration = col_integer(),
      #       starttime = col_datetime("%m/%d/%Y %H:%M"),
      #       "start station id" = col_integer()
      #     )
      #   )
      
      
      read_file(c.csv.file) %>%
        str_replace_all('"{2,3}', '"') %>%
        read_csv_chunked(
          callback = fn_append_to_sqlite("my_table"),
          col_names = TRUE,
          progress = TRUE,
          col_types = cols_only(
            tripduration = col_integer(),
            starttime = col_datetime("%m/%d/%Y %H:%M"),
            "start station id" = col_integer()
          )
        )
      
      # starttime was parsed as character, hence supplying own col class with
      # customized dattime format, as deafult format failed.
      # check "reduce data v 4.R" for details
      
      
    } # end else if - 2015
    else{
      # nested if else BLOCK, for normal .csv file
      # special handling for all except a) 201408 b) four data files from 2015
      
      cat("\n entering nested else block for normal .csv files - ")
      cat("\n these have second in start time field, along with quotes in col name and data")
      cat("\n")
      
      # 4. readr from tidyverse supports read_csv()
      # but first remove the quotes
      # df.1 = read_file(c.csv.file) %>%
      #   str_replace_all('"{2,3}', '"') %>%
      #   read_csv(col_names = TRUE,
      #            col_types = cols(starttime = col_datetime("%m/%d/%Y %H:%M:%S")))
      
      # moving from read_csv to read_csv_chunked
      # df.1 = read_file(c.csv.file) %>%
      #   str_replace_all('"{2,3}', '"') %>%
      #   read_csv(
      #     col_names = TRUE,
      #     col_types = cols_only(
      #       tripduration = col_integer(),
      #       starttime = col_datetime("%m/%d/%Y %H:%M:%S"),
      #       "start station id" = col_integer()
      #     )
      #   )
      
      
      df.1 = read_file(c.csv.file) %>%
        str_replace_all('"{2,3}', '"') %>%
        read_csv_chunked(
          callback = fn_append_to_sqlite("my_table"),
          col_names = TRUE,
          progress = TRUE,
          col_types = cols_only(
            tripduration = col_integer(),
            starttime = col_datetime("%m/%d/%Y %H:%M:%S"),
            "start station id" = col_integer()
          )
        )
      
      
      # starttime was parsed as character, hence supplying own col class with
      # customized dattime format, as deafult format failed.
      # check "reduce data v 1.R" for details
      
      
    } # end else - for the inner if (handling quotes)
    
  }  else  {
    message('no matching csv file found. downloading it')
    
    cat("\n downloading", c.zip.name)
    
    c.zip.name = basename(URL)
    c.file.path = file.path(c.home.dir, c.data.dir, c.zip.name)
    c.data.folder = file.path(c.home.dir, c.data.dir)
    
    # SRC: http://stackoverflow.com/questions/3053833/using-r-to-download-zipped-data-file-extract-and-import-data/3053883
    # 1. Create a temp. file name (eg tempfile())
    myzip <- unz(URL, filename = basename(URL))
    
    # 2. Use download.file() to fetch the file into the temp. file
    download.file(URL, destfile = c.file.path)
    
    # 3. extract the target file from temp. file
    f.name = unzip(c.file.path, exdir = c.data.folder)
    
    # TODO: this should ideally be replica of inner if-elseif-if
    # from teh outer if part. Because we do not know which file
    # is being downloaded. 201408, 2015 specials, or the rest
    
    # TODO: the read_csv should be replaced by read_csv_chunked
    # as has been done in the inner if-elseif- loop above
    # 4. readr from tidyverse supports read_csv()
    #df.1 = read_csv(f.name, col_names = TRUE)
    df.1 = read_file(c.csv.file) %>%
      str_replace_all('"{2,3}', '"') %>%
      read_csv(col_names = TRUE,
               col_types = cols(starttime = col_datetime("%m/%d/%Y %H:%M:%S")))
    
    # starttime was parsed as character, hence supplying own col class with
    # customized dattime format, as deafult format failed.
    # check "reduce data v 1.R" for details
    
  } #end outer else
  
  ## 5,6, and 7
  # i.e
  # 5. fix col names
  # 6. remove all but first and last row
  # 7. remove all but 3 desired cols
  # now moves to helper fn: fn_append_to_sqlite
  # which is called from read_csv_chunked
  
  # # 5. fix col names for df.1
  # names(df.1) = gsub(" ", "_", names(df.1))
  #
  # # 6. remove all but first and last rows
  # # TODO: remove this, as we want complete data, not just two rows
  # df.1 <-
  #   df.1 %>%
  #   filter(row_number() %in% c(1, n()))
  #
  # # 7. remove all but few cols
  # df.1 <-
  #   df.1 %>%
  #   select(starttime, start_station_id, tripduration)
  
  ## view the df written
  # TODO: comment this
  #cat("head(df.1)", head(df.1))
  #print.data.frame(head(df.1))
  
  # TODO: Multiple Inserts of same data are happening
  # if you call this function again and again
  
  # every time after first - insert into
  # SRC:
  # http://stackoverflow.com/questions/26568182/is-it-possible-to-insert-add-a-row-to-a-sqlite-db-table-using-dplyr-package
  
  # Use overwrite = TRUE to force overwriting of an existing table, and append =
  # TRUE to append to an existing table. --> overwrite = TRUE leads to error
  
  # the db insetion part moves into
  # fn: fn_append_to_sqlite
  
  # db_insert_into(
  #   con = my_db$con,
  #   table = "my_table",
  #   values = df.1,
  #   overwrite = TRUE
  # )
  
  # view the df written
  # TODO: comment this
  # head(df.1)
  
  # remove the memory-heavy df
  # rm(df.1)
  
  # remove temp var
  rm(myzip)
  
  
  
} # end function fn_downloadZip

### Description:
## this function creates a list of files to download
### I/P:
## None
### O/P:
## List of zip files to download and read

fn_filesToDownload <- function(URL) {
  ### Create a matrix or combo of all files to be downloaded
  # SRC:
  # https://gist.github.com/patternproject/0a7ade8fa3d85453076d9bafc2087127
  
  ## Method 1 (Preferred due to clarity of output)
  df <- expand.grid(m = 1:12, y = 2014:2016)
  c.files <-
    sprintf("https://s3.amazonaws.com/tripdata/%d%02d-citibike-tripdata.zip",
            df$y,
            df$m)
  
  # for Testing reducing the size of c.files
  # df <- expand.grid(m = 1:12, y = 2013)
  # c.files <- sprintf("https://s3.amazonaws.com/tripdata/%d%02d-citibike-tripdata.zip", df$y, df$m)
  
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
  
  # for Testing reducing the c.files
  # 2013: 01 to 10
  # i.remove <- c (1:10)
  # c.files = c.files[-i.remove]
  
  ## Remove file names that do not exist or not required
  # Analysis limited to Aug 2014 to Aug 2016
  # # 2014: 01 t0 07
  i.remove <- c (1:7)
  # # 2015: None
  # # 2016: 09 to 12
  i.remove <- c (i.remove, 33:36)
  # # updating file vector
  c.files = c.files[-i.remove]
  
  # remove temp vars
  rm(i.remove, df)
  
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

fn_dbSafeNames = function(names) {
  names = gsub('[^a-z0-9]+', '_', tolower(names))
  names = make.names(names, unique = TRUE, allow_ = TRUE)
  names = gsub('.', '_', names, fixed = TRUE)
  names
}

### Description:
## a function to insert the chunked part of csv file
## into the sql db 
### I/P:
## x = chunk read from csv file 
## chunk size is determined by global operator i_chunk_size
### O/P:
## None 
#fn_append_to_sqlite <- function(x, pos, table_name) {
fn_append_to_sqlite <- function(x, pos) {

  # print(pos)
  # print.data.frame(x)
  # print(table_name)
  
  # 5. fix col names for df.1
  names(x) = gsub(" ", "_", names(x))
  
  # 6. remove all but first and last rows
  # TODO: remove this, as we want complete data, not just two rows
  # x <-
  #   x %>%
  #   #filter(row_number() %in% c(1, n()))
  #   #slice(1:n()) -> effectively the entire df
  #   slice(c(1,n()))
  
  # 7. remove all but few cols
  x <-
    x %>%
    select(starttime, start_station_id, tripduration)
  
  print.data.frame(x)
  
  # insert into db
  dbWriteTable(con = my_db$con, 
               #table = table_name, 
               name = "my_table", 
               value = x, 
               append = TRUE)
  
  # instead of 
  # db_insert_into(
  #   con = my_db$con,
  #   table = "my_table",
  #   values = df.1,
  #   overwrite = TRUE
  # )
  
  
  #str(x)
  #print.data.frame(x)
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

# read by read_csv_chunked
i.chunk_size = 1000
table_name = "my_table"

## SQL Set-up
# https://datascienceplus.com/working-with-databases-in-r/
# http://www.datacarpentry.org/R-ecology-lesson/05-r-and-databases.html
c.db.path = file.path(c.home.dir, c.data.dir, c.db.name)
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
my_db <- src_sqlite(path = c.db.path, create = FALSE)
my_con <- my_db$con

# List the tables in the db
# src_tbls(my_db) # or alternately
dbListTables(my_con)

# if TABLE exists but you want to remove it and redo the whole loop of
# reading csv files
#dbRemoveTable(my_con, "my_table")
#dbRemoveTable(my_con, "sqlite_stat1")

# checking length of tables is not a valid criteria
# i.db.tables = (dbListTables(my_con)) %>% length()

# shifting to direct testing of table existence
if (dbExistsTable(my_con, "my_table"))
{
  message("my_test TABLE already exists in the database")
  
} else{
  
  my_db <-
    src_sqlite(path = c.db.path, create = TRUE) # create =TRUE creates
  
  # 2. Create Tables
  fn_dbCreateTable()
  
}

# some output of what exists as default data
bikeData = tbl(my_db, "my_table")
head(bikeData)
View(bikeData)

# 3. List of files to download
c.files = fn_filesToDownload()

# reduced the set of files to download
# c.files = c.files[1:3]

# read_csv failing as the input files starting from
# "https://s3.amazonaws.com/tripdata/201409-citibike-tripdata.zip
# have a strange format. Both col names and data are quoted
# An if block added to fn_downloadZip to distinguish between the two cases
# if(file name contains 201408 then regular read_csv)
# else remove quotes and then regular read_csv


# Insert this files into the db
c.files %>%
  map(fn_downloadZip)




# 3. List the tables in the database
# https://cran.r-project.org/web/packages/dplyr/vignettes/databases.html
# src_tbls(my_db) # alternately
dbListTables(my_con)

# 4. We use tbl to connect to tables within the database.
bikeData = tbl(my_db, "my_table")
head(bikeData)

# tail does not work, using sql to get row count
query =
  "SELECT COUNT(*)
FROM my_table"
rs = dbSendQuery(my_db$con, query)
df.master = fetch(rs, n = -1)
head(df.master)
# result says 48K records




# memory intensive - use with care
View(bikeData)
# kable(bikeData)

# 5. We can see the query dplyr has generated:
query.result = filter(bikeData, start_station_id == 268)
query.result
query.result$query
explain(query.result)

# 6. Saving the sql data as a R data
query =
  "SELECT *
   FROM my_table"

rs = dbSendQuery(my_db$con, query)
df.master = fetch(rs, n = -1)
head(df.master)

#c.df.master = "df.master.csv"
c.df.master = "df.master.2.csv"
c.df.master = file.path(c.home.dir, c.data.dir, c.df.master)
write_csv(x=df.master, path=c.df.master)

# TODO: this might be required later. 
# However, when working with really large CSV files, you do not want to load the
# entire file into memory first (this is the whole point of this tutorial). An
# alternative strategy is to load the data from the CSV file in chunks (small
# sections) and write them step by step to the SQlite database.

# Details here:
# SRC: https://inbo.github.io/tutorials/data-handling-large-files-R.html

## `````````````````````````````````````````````

## `````````````````````````````````````````````
#### DPLYR vs SQL  ####
## `````````````````````````````````````````````
# Tried to use dplyr SQL interface but the results
# have class as: # tbl_sqlite" "tbl_sql" "tbl_lazy" "tbl"
# with somewhat restriction on what operations can be done
# such as: windows functions are not supported by SQLLITE

# Instead run the basic aggregation query in SQL
# The results are returned as r df
# And you can live happily ever after

# """"""""""""
# 1. dplyr SQL
# """"""""""""

# subset of unique values
# distinct(bikeData) -> df.master
# View(df.master)

# TODO: write the df.master back to the db

# To read the whole table into the workspace as a new data.frame
# SRC:
# http://r.789695.n4.nabble.com/RSQLite-to-input-dataframe-td3173334.html
# my.data.copy <- dbReadTable(my_db$con, "my_table")
# str(my.data.copy) # compare it with str(df.master)
# but this is whole data frame, not the query result

# run a simple query
# df.master %>%
#   filter(start_station_id == 164) %>%
#   #str()
#   count()

# aggregate table for station count
# df.master %>%
#   group_by(starttime) %>%
#   summarise(count = n_distinct(start_station_id))


# """"""""""""
# 2. Pure SQL
# """"""""""""

# Alternately running SQL command gets you a r df
# SRC:
# http://www.utsc.utoronto.ca/~butler/climate-lab/climate-lab.html#/32
# query="select * from my_table"
# rs=dbSendQuery(my_db$con,query)
# d=fetch(rs,n=-1)
# head(d)
# str(d)

# SQL for unique values in start_time
# SRC:
#  http://stackoverflow.com/questions/7454393/how-to-select-rows-based-on-distinct-values-of-a-column-only
# query = "SELECT MIN(starttime) FROM my_table GROUP BY starttime"
#
# query = "SELECT * FROM my_table
# WHERE starttime IN
# (SELECT MIN(starttime) FROM my_table GROUP BY starttime)"
#
# rs=dbSendQuery(my_db$con,query)
# d=fetch(rs,n=-1)
# head(d)

# SQL for group by
# query = "SELECT COUNT(start_station_id), starttime
# FROM my_table
# GROUP BY starttime"

# rs=dbSendQuery(my_db$con,query)
# d=fetch(rs,n=-1)
# head(d)

# SQL for group by from unique
# query = "SELECT COUNT(DISTINCT start_station_id), starttime, SUM(DISTINCT tripduration)
# FROM my_table
# GROUP BY starttime"

# rs=dbSendQuery(my_db$con,query)
# d=fetch(rs,n=-1)
# head(d)

# SRC:
# http://www.sqlteam.com/article/how-to-use-group-by-with-distinct-aggregates-and-derived-tables
# says sum(distinct) does not work properly
# it groups by, then removes duplicates in the col of interest, i.e. trip duration
# and share their results. Which we do not want. If two trips had a similar duration
# of 10, these two 10 should be added.

# query = "select starttime, count(*) as ItemCount, sum(tripduration) as TotalDuration
# from my_table
# group by starttime"

# but we can ignore it
# our starttime has to be unique, multiple rows are because of multiple insertions of the same value
# as we did not enforce key constraint while inserting
## `````````````````````````````````````````````

## `````````````````````````````````````````````
#### Manipulate Data ####
## `````````````````````````````````````````````

#1. Use SQL to get the aggregated table
# SQL for group by from unique
query =
  "SELECT
starttime,
COUNT(DISTINCT start_station_id) as total_stations,
SUM(DISTINCT tripduration) as total_trips_duration
FROM my_table
GROUP BY starttime"

rs = dbSendQuery(my_db$con, query)
df.master = fetch(rs, n = -1)
head(df.master)



## `````````````````````````````````````````````


## `````````````````````````````````````````````
#### Plot 1 ####
## `````````````````````````````````````````````
## `````````````````````````````````````````````


## `````````````````````````````````````````````
#### Clean up ####
## `````````````````````````````````````````````

# 6. Closing Connection
# SRC:
# http://stackoverflow.com/questions/26331201/disconnecting-src-tbls-connection-in-dplyr
dbDisconnect(my_db$con)

# TODO: keeping the database intact

# remove table for cleanup - not required everytime
#dbRemoveTable(my_con, "my_table")
#dbRemoveTable(my_con, "sqlite_stat1")

#rm(bikeData)
#rm(bikes_sqlite)

# rm(list=ls())
## `````````````````````````````````````````````
