# dimensions processed correctly

    Code
      emdn_get_dimensions_info(summary, format = "tibble")
    Output
      # A tibble: 3 x 5
        dimension label uom   type       range                                        
            <int> <chr> <chr> <chr>      <chr>                                        
      1         1 lat   deg   geographic <NA>                                         
      2         2 long  deg   geographic <NA>                                         
      3         3 time  s     temporal   1958-02-16T00:00:00.000Z - 2016-11-16T00:00:~

