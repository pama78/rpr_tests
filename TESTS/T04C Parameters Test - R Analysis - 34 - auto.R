############################################
# Script : T04C Parameters Test - R Analysis - 34 - auto.R
# Purpose: Run the flow of k-Proto and NN on bigger samples of data
# Flow   :
#         1) import data from DB (manipulate, split, format to factors)
#         2) call function to do all in one step
#             k-Proto for both groups
#             NN for both groups
#             store results to DB
#         3) repeat with different parameters setting
############################################
#remove(list = ls())

#Settings
 DB_INST="{DB_SERVER}:{DB_PORT}/{SID}"
 DB_JDBC="C:/app/Oracle12/product/12.2.0/client_1/dmu/jlib/ojdbc6.jar"  #Path to ojdbc
 DB_USER="{DB_USER}"
 DB_PASS= "{DB_PASSWORD}"

#first use - install packages
#install.packages(c ('RJDBC', 'rJava', 'dplyr', 'clustMixType'))
 library(clustMixType)
 library(dplyr) 
 library(neuralnet)
 library(RJDBC)
 
#prepare environment 
 options(java.parameters = "-Xmx8048m")  #avoid java out of memory
 source("C:/!UCL/Alfa/ERS1/05 RPR test functions.R")
 jdbcDriver =JDBC("oracle.jdbc.OracleDriver",classPath= DB_JDBC)
 jdbcConnection =dbConnect(jdbcDriver, paste0("jdbc:oracle:thin:@//",DB_INST), DB_USER , DB_PASS)
 
#Connectivity test
 dbReadTable(jdbcConnection,'dual')
  
#remote select to Oracle from R studio, select count
 dbGetQuery(jdbcConnection, "select count(*) from EVENT_NEW") #552960

#import data from DB (from Oracle DB)
 doImportAndPrepareData() 

#Prerpare params
   EDR.g1.cols<-names(which(colSums(is.na(EDR.g1)) == 0))[-c(1:3)]  
   EDR.g2.cols<-names(which(colSums(is.na(EDR.g2)) == 0))[-c(1:3)]  
   EDR.g1.cols2=c("TARIFF", "RATE_OFFER", "EVENT_TYPE", "EVENT_TYPE_GROUP", "IS_INT", "UNIT_RATE" )   
   EDR.g2.cols2=c("TARIFF", "RATE_OFFER", "EVENT_TYPE", "EVENT_TYPE_GROUP", "CALL_ZONE",  "CALL_DIRECTION",  "IS_INT",  "UNIT_RATE" ) 
   
   kg1.sqrt<-round(sqrt(nrow (EDR.g1)))
   kg2.sqrt<-round(sqrt(nrow (EDR.g2)))
   
   lg1_est <- lambdaest(EDR.g1[,EDR.g1.cols])    
   lg2_est <- lambdaest(EDR.g2[,EDR.g2.cols])
   lg1_est2 <- lambdaest(EDR.g1[,EDR.g1.cols2])    
   lg2_est2 <- lambdaest(EDR.g2[,EDR.g2.cols2])

   kg1.sqrt; kg2.sqrt; lg1_est; lg2_est; lg1_est2; lg2_est2  #[1] 83, 166, 24409.62, 12962.03, 10897.26, 166.1368
  
 #GROUP A - MORE COLS
 ##################################################################################################
  #tst1 - EVENT_ID 2 3 4 5   7 10 11 12
   kproto_NN_execute(kg1.sqrt,kg2.sqrt, lg1_est, lg2_est,  EDR.g1.cols, EDR.g2.cols, 5, 5 )
 
  #tst2 - EVENT_ID 2 3 4 5 6 7 10 11 12
   kproto_NN_execute(100,100, lg1_est, lg2_est,  EDR.g1.cols, EDR.g2.cols , 5, 5 )
   
  #tst3 - EVENT_ID 2 3 4 5 6 7 10 11 12
   kproto_NN_execute(kg1.sqrt,kg2.sqrt, 100, 100,  EDR.g1.cols, EDR.g2.cols , 5, 5 )
  
  #tst4 - EVENT_ID 2 3 4 6 7 10 11 12
   kproto_NN_execute(100, 100, 100, 100,  EDR.g1.cols, EDR.g2.cols, 5, 5 )
   
  #tst5 - EVENT_ID 3 4 5 7 10 11 12
   kproto_NN_execute(100, 100, 1, 1,  EDR.g1.cols, EDR.g2.cols, 5, 5 )

  #tst6 - EVENT_ID 2 3 5 7 10 11 12
   kproto_NN_execute(50, 50, 1, 1,  EDR.g1.cols, EDR.g2.cols, 5, 5 )

  #tst7 - EVENT_ID 2 3 6 7 10 11 12
   kproto_NN_execute(10, 10, 1, 1,  EDR.g1.cols, EDR.g2.cols, 5, 5 )

  #tst8 - EVENT_ID 2 3 6 7 10 11 12
   kproto_NN_execute(5, 5, 1, 1,  EDR.g1.cols, EDR.g2.cols, 5, 5 )
   
  #tst9 - EVENT_ID 2 4 6 7 10 12 
   kproto_NN_execute(5, 5, lg1_est, lg2_est,  EDR.g1.cols, EDR.g2.cols, 5, 5 )
   
  #tst10 - EVENT_ID 2 3 6 7 10 11 12 
   kproto_NN_execute(10, 10, 0.1, 0.1,  EDR.g1.cols, EDR.g2.cols, 5, 5  )
   
#GROUP B - LESS COLS
#################################################################################################
   #tst1 - EVENT_ID 2 3 4 5   7 10 11 12
   #       EVENT_ID 2 3 4 5 6 7 10 11 12 #run2
   kproto_NN_execute(kg1.sqrt,kg2.sqrt, lg1_est2, lg2_est2,  EDR.g1.cols2, EDR.g2.cols2, 5, 5  )
   
   #tst2 - EVENT_ID 2 3 4 5 6 7 10 11 12
   #       EVENT_ID 2 3 4   6 7 10 11 12
   kproto_NN_execute(100,100, lg1_est2, lg2_est2,  EDR.g1.cols2, EDR.g2.cols2, 5, 5  )
   
   #tst3 - EVENT_ID 2 3 4 5 6 7 10 11 12
   #       EVENT_ID 2 3 4 5 6 7 10 11 12
   kproto_NN_execute(kg1.sqrt,kg2.sqrt, 100, 100,  EDR.g1.cols2, EDR.g2.cols2, 5, 5  )
   
   #tst4 - EVENT_ID 2 3 4   6 7 10 11 12
   #       EVENT_ID 2 3 4   6 7 10 11 12
   kproto_NN_execute(100, 100, 100, 100,  EDR.g1.cols2, EDR.g2.cols2, 5, 5 )
   
   #tst5 - EVENT_ID 3 4 5     7 10 11 12
   #       EVENT_ID 2 3 4 5 6 7 10 11 12
   kproto_NN_execute(100, 100, 1, 1,  EDR.g1.cols2, EDR.g2.cols2, 5, 5 )
   
   #tst6 - EVENT_ID 2 3   5   7 10 11 12
   #       EVENT_ID 2 3 4 5 6 7 10 11 12
   kproto_NN_execute(50, 50, 1, 1,  EDR.g1.cols2, EDR.g2.cols2, 5, 5 )
   
   #tst7 - EVENT_ID 2 3   6 7 10 11 12
   #       EVENT_ID 2 3 5 6 7 10 11 12
   kproto_NN_execute(10, 10, 1, 1,  EDR.g1.cols2, EDR.g2.cols2, 5, 5 )
   
   #tst8 - EVENT_ID 2 3 6 7 10 11 12
   #       EVENT_ID 2 3 6 7 10 11 12
   kproto_NN_execute(5, 5, 1, 1,  EDR.g1.cols2, EDR.g2.cols2, 5, 5  )
   
   #tst9 - EVENT_ID 2 4   6 7 10    12 
   #       EVENT_ID 2 4 5 6 7 10 11 12
   kproto_NN_execute(5, 5, lg1_est2, lg2_est2,  EDR.g1.cols2, EDR.g2.cols2, 5, 5  )
   
   #tst10 - EVENT_ID 2 3   6 7 10 11 12 
   #        EVENT_ID 2 3 5 6 7 10 11 12
   kproto_NN_execute(10, 10, 0.1, 0.1,  EDR.g1.cols2, EDR.g2.cols2, 5, 5  )
   

