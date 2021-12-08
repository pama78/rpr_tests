############################################
# Script : Test3 R Analysis
# Purpose: Run the flow of k-Proto and NN on bigger samples of data
# Flow   :
#         1) import data from DB (maninuplate, split, format to factors)
#         2) call function to do all in one step
#             k-Proto for both groups
#             NN for both groups
#             store results to DB
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

#import data from DB (from Oracle DB)
 doImportAndPrepareData()

#Prerpare params
 EDR.g1.cols=c("TARIFF", "RATE_OFFER", "EVENT_TYPE", "EVENT_TYPE_GROUP", "IS_INT", "UNIT_RATE" )   
 EDR.g2.cols=c("TARIFF", "RATE_OFFER", "EVENT_TYPE", "EVENT_TYPE_GROUP", "CALL_ZONE",  "CALL_DIRECTION",  "IS_INT",  "UNIT_RATE" ) 
 lg1_est <- lambdaest(EDR.g1[,EDR.g1.cols])    
 lg2_est <- lambdaest(EDR.g2[,EDR.g2.cols])
 kg1<-100  #100 groups
 kg2<-100  #100 groups

#execute NN and kproto and store results to DB 
 kproto_NN_execute(kg1,kg2, lg1_est, lg2_est,  EDR.g1.cols, EDR.g2.cols, 5, 5  )

 #filter(EDR_CLUST_NN, CMP_RESULTS == "New") [,c("RATE_OFFER","EVENT_TYPE", "UNIT_RATE", "UNIT_RATE_NN","UNIT_RATE_NN_DIFF")]
  
 
 