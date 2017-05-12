## `````````````````````````````````````````````
#### Read Me ####
## `````````````````````````````````````````````

# v 1: This fn has become so complicated that it needed to be managed in a sepearte file
#      The tricky part is the if else with nested part
#      a) The outer if- else if - else, corresponds to following:
#       if -> file exists with expanded file name
#       else if -> file exists with normal file name
#       else -> download it
#      b) The nested or inner if- else if - else, corresponds to following:
#       if -> file exists with normal file name and has 201408 in the name
#         read it normally
#       else if -> file exists with normal file name and is one of the four funny 2015 files
#         read start time with missing second part
#       else -> file exists with normal file name
#         read start time with second part but first remove strange quotes

#       normal means the file name is not expanded. 
#       Quote Issues or DateTime issues are still there and are 
#       handled by inner if-elseif-else blocks
#       first if: 201408
#       else if: 2015 files
#       else: all other files

# v 2:  col_datetime("%d/%m/%Y %H:%M") should have been col_datetime("%m/%d/%Y %H:%M")
#       order of d and m changed (first two parms)


## `````````````````````````````````````````````



fn_downloadZip <- function(URL) {
  #URL = c.files[1]
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
    df.1 = read_csv(c.csv.file.ext, col_names = TRUE)
    
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
    cat("\n normal means the file name is not expanded. Quote Issues or DateTime issues still there")
    cat("\n corresponding csv file: ", c.csv.file)
    cat("\n")
    message('file already exists')
    
    # somehow files after
    # "https://s3.amazonaws.com/tripdata/201408-citibike-tripdata.zip"
    # i.e.
    # "https://s3.amazonaws.com/tripdata/201408-citibike-tripdata.zip"
    # onwards have a strange syntax
    # where each of col names and data are wrapped in ""
    # hence we check if file name has 201408
    if (str_detect(c.csv.file, "201408"))
    {
      # nested if BLOCK, for normal .csv file
      # special handling for 201408 data file
      
      cat("\n entering nested if block for normal .csv files - special handling for data file: 201408 ")
      cat("\n")
      
      # 4. readr from tidyverse supports read_csv()
      df.1 = read_csv(c.csv.file, col_names = TRUE)
      
    } else if (str_detect(c.csv.file, "201501|201502|201503|201506"))
    {
      # nested if else BLOCK, for normal .csv file
      # special handling for four data files,
      # namely: 201501, 201502, 201503 and 201506
      # Refer to fn_downloadZip output v3 for details
      
      cat("\n entering nested if block for normal .csv files - special handling for data file: 201501,201502,201503,201506")
      cat("\n these have missing second in start time field")
      cat("\n")
      
      # 4. readr from tidyverse supports read_csv()
      # but first remove the quotes
      df.1 = read_file(c.csv.file) %>%
        str_replace_all('"{2,3}', '"') %>%
        read_csv(col_names = TRUE,
                 col_types = cols(starttime = col_datetime("%m/%d/%Y %H:%M")))
      
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
      df.1 = read_file(c.csv.file) %>%
        str_replace_all('"{2,3}', '"') %>%
        read_csv(col_names = TRUE,
                 col_types = cols(starttime = col_datetime("%m/%d/%Y %H:%M:%S")))
      
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
  
  # TODO: Multiple Inserts of same data are happening
  # if you call this function again and again
  
  # every time after first - insert into
  # SRC:
  # http://stackoverflow.com/questions/26568182/is-it-possible-to-insert-add-a-row-to-a-sqlite-db-table-using-dplyr-package
  
  # Use overwrite = TRUE to force overwriting of an existing table, and append =
  # TRUE to append to an existing table. --> overwrite = TRUE leads to error
  
  db_insert_into(
    con = my_db$con,
    table = "my_table",
    values = df.1,
    overwrite = TRUE
  )
  
  # view the df written
  # TODO: comment this
  head(df.1)
  
  # remove the memory-heavy df
  rm(df.1)
  
  # remove temp var
  rm(myzip)
  
} # end function fn_downloadZip
