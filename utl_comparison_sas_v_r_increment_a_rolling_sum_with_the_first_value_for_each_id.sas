Comparison SAS v R Increment a rolling sum with the first value for each id

INPUT
=====

 SD1.HAVE total obs=8

                     |  RULES
                     |  ==============
  OTHER ID  VALUE    |          CUMSUM
                     |
    1    1    10     |   10       10
    2    1    10     |            10      * only accumlate first occurance and retain it
    3    2    20     |   10+20    30
    4    2    20     |            30
    5    3    10     |   30+10    40      * strict accumulation because no duplicates below
    6    4    30     |   30+40    70
    7    5    40     |   70+40   110
    8    6    50     |  110+50   160


PROCESS
=======

  SAS
  ===
   data want_sas;
     set sd1.have;
     retain cumsum 0;
     by id;
     if first.id then cumsum=cumsum+value;
   run;quit;

  R    ( A little bit Klingon?)
  ==
    1 data %>%
          group_by(id) %>% nest() %>%
          mutate(cum_col = cumsum(sapply(data, function(dat) dat$value[1]))) %>%
          unnest()


    2 summarise_f <- function(data) data %>%
          group_by(id) %>%
          summarise(val = first(value)) %>%
          mutate(cum_col = cumsum(val)) %>%
          select(-val) %>%
          inner_join(data, by="id")

      nest_f <- function(data) data %>%
          group_by(id) %>% nest() %>%
          mutate(cum_col = cumsum(sapply(data, function(dat) dat$value[1]))) %>%
          unnest()


    3 library(dplyr)
      data %>%
        group_by(id) %>%
        mutate(cols = c(value[1], rep(0, n() -1))) %>%
        ungroup() %>%
        mutate(cum_col = cumsum(cols)) %>%
        select(-cols)

    4 library(dplyr)
      data %>%
           mutate(cum_col = cumsum(value*!duplicated(id)))

OUTPUT
======

  WANT_SAStotal obs=8

   OTHER    ID    VALUE    CUMSUM

     1       1      10        10
     2       1      10        10
     3       2      20        30
     4       2      20        30
     5       3      10        40
     6       4      30        70
     7       5      40       110
     8       6      50       160



*                _              _       _
 _ __ ___   __ _| | _____    __| | __ _| |_ __ _
| '_ ` _ \ / _` | |/ / _ \  / _` |/ _` | __/ _` |
| | | | | | (_| |   <  __/ | (_| | (_| | || (_| |
|_| |_| |_|\__,_|_|\_\___|  \__,_|\__,_|\__\__,_|

;

proc datasets lib=work kill;
run;quit;
options validvarname=upcase;
libname sd1 "d:/sd1";
data sd1.have;
 retain other id value;
 input id value other;
cards4;
 1 10 1
 1 10 2
 2 20 3
 2 20 4
 3 10 5
 4 30 6
 5 40 7
 6 50 8
;;;;
run;quit;

*                           _       _   _
 ___  __ _ ___    ___  ___ | |_   _| |_(_) ___  _ __
/ __|/ _` / __|  / __|/ _ \| | | | | __| |/ _ \| '_ \
\__ \ (_| \__ \  \__ \ (_) | | |_| | |_| | (_) | | | |
|___/\__,_|___/  |___/\___/|_|\__,_|\__|_|\___/|_| |_|

;

data want_sas;
  set sd1.have;
  retain cumsum 0;
  by id;
  if first.id then cumsum=cumsum+value;
run;quit;

*____              _       _   _
|  _ \   ___  ___ | |_   _| |_(_) ___  _ __
| |_) | / __|/ _ \| | | | | __| |/ _ \| '_ \
|  _ <  \__ \ (_) | | |_| | |_| | (_) | | | |
|_| \_\ |___/\___/|_|\__,_|\__|_|\___/|_| |_|

;

%utl_submit_r64('
source("c:/Program Files/R/R-3.3.2/etc/Rprofile.site",echo=T);
library(dplyr);
library(SASxport);
library(Hmisc);
library(haven);
have<-read_sas("d:/sd1/have.sas7bdat");
want<- have %>%
     mutate(cum_col = cumsum(VALUE*!duplicated(ID)));
want;
write.xport(want,file="d:/xpt/want_r.xpt");
');

libname xpt xport "d:/xpt/want_r.xpt";
proc print data=xpt.want;
run;quit;

