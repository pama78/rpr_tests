####################################################################################################################
# Script : Test01 - R Analysis
# Purpose: Flow of cluster analysis on the practical example
# Flow   :
#           1) IMPORT DATA FROM DB 
#           2) FORMAT DATA (FACTORS, HANDLE NULLS, SPLIT DATA BY EMPTY COLS)
#           3) K-PROTOTYPES PARAMETERS ANALYSIS (k and Lambda)
#           4) K-PROTOTYPES RUN 
#           5) K-PROTOTYPES RESULTS PROCESS
#           6) UPLOAD AUGMENTED DATA BACK TO DB
####################################################################################################################

#Settings 
 DB_INST="{DB_SERVER}:{DB_PORT}/{SID}"
 DB_JDBC="C:/app/Oracle12/product/12.2.0/client_1/dmu/jlib/ojdbc6.jar"  #Path to ojdbc
 DB_USER="{DB_USER}"
 DB_PASS= "{DB_PASSWORD}"

#first use - install packages
 install.packages('RJDBC')
 install.packages('rJava')
 install.packages("dplyr")
 install.packages('clustMixType')
 
# 1) IMPORT DATA FROM DB ###########################################################################################
 #DB Connection + connectivity test
 library(dplyr) 
 library(RJDBC)
 jdbcDriver =JDBC("oracle.jdbc.OracleDriver",classPath= DB_JDBC)
 jdbcConnection =dbConnect(jdbcDriver, paste0("jdbc:oracle:thin:@//",DB_INST), DB_USER, DB_PASS)
 dbReadTable(jdbcConnection,'dual')  #Connectivity test
 dbGetQuery(jdbcConnection, "select count(*) from EVENT_NEW") #remote select to Oracle from R studio, select count
 
 #Import data table from DB to R studio
 start_time <- Sys.time()
 EDR=dbReadTable(jdbcConnection,'EVENT_NEW')
 Sys.time()-start_time
 head (EDR)
 nrow(EDR)    #4320
 
# 2a) FORMAT DATA (FACTORS) #####################################################################################
 #change all relevant categorical attributes to factor - based on the list in variable cols:
 cols<-c("CUSTOMER_ID","CUSTOMER_DETAILS","TARIFF","RATE_OFFER","EVENT_TYPE","CALL_ZONE",
           "IS_INT","EVENT_TYPE_GROUP","CALL_DIRECTION","CMP_RESULTS","CMP_DIFF","CMP_DETAILS")
 EDR[,cols] <- lapply(EDR[,cols], factor )  
 str(EDR) #show data types

# 2b) FORMAT DATA (HANDLE NULLS) ###############################################################################
 #Show columns with empty values
 names(which(colSums(is.na(EDR)) > 0))  
 
 #Define function for counting empty (NA) values
 naCount <- function(x){
    list( sum(is.na(x))  , sum(!is.na(x)) )
 }

 #Count NA(empty) values in the table EDR 
 sapply(EDR, naCount) #call function 

# 2c) FORMAT DATA (SPLIT DATA BY EMPTY COLS) ##################################################################
 #group split from EDR to EDR.g1 and EDR.g2
 EDR.g1<-EDR[is.na(EDR$ROUNDED_DURATION ),]    #group 1, where rounded_duration is empty
 EDR.g2<-EDR[!is.na(EDR$ROUNDED_DURATION ),]   #group 2, all the rest
 nrow(EDR.g1) #first group include 864 rows
 nrow(EDR.g2) #second group include 3456 rows

 #validate groups 1 and 2
 sapply(EDR.g1, naCount) #columns are empty for all rows: CALL_ZONE CALL_DIRECTION DURATION ROUNDED_DURATION
 sapply(EDR.g2, naCount) #columns are empty for all rows: VOLUME and ROUNDED_VOLUME
 
# 3) K-PROTOTYPES PARAMETERS ANALYSIS  ########################################################################
 #Step 1: initialization of library
 library(clustMixType)

 #Step 2: remind empty columns from EDR.g1 
 names(which(colSums(is.na(EDR.g1))>0)) # CALL_ZONE, CALL_DIRECTION, DURATION, ROUNDED_DURATION
 names(which(colSums(is.na(EDR.g2))>0)) # VOLUME, ROUNDED_VOLUME

 #Step 3: store all other columns to variable EDR.g1.cols, and exclude identification details 
 #excluded first three - "EVENT_ID", "CUSTOMER_ID", "CUSTOMER_DETAILS"
 EDR.g1.cols<-names(which(colSums(is.na(EDR.g1)) == 0))[-c(1:3)]  
 EDR.g2.cols<-names(which(colSums(is.na(EDR.g2)) == 0))[-c(1:3)]  
 c ("group1:", EDR.g1.cols)
 c ("group2:", EDR.g2.cols)

 #Step 4: Lambda estimation
 lbd.g1  <- lambdaest(EDR.g1[,EDR.g1.cols])  # 24434.31
 lbd.g2  <- lambdaest(EDR.g2[,EDR.g2.cols])  # 15411.15 
 
 #Step 5: K value range estimation (several approaches)
 # k.g1.range<-30:40 #user defined range/not used
 # k.g1.range<-(round(sqrt(nrow(EDR.g1))-5)):(round(sqrt(nrow(EDR.g1))+5)) ##around the squared amont of rows +-5/not used
 k.g1.range<-seq.int (round(sqrt(nrow(EDR.g1))), (2*(round(sqrt(nrow(EDR.g1))))),
                        by=round(sqrt(nrow(EDR.g1))/10))  #10 values from range between 1 sqrt and 2 sqrt of number of rows
 k.g2.range<-seq.int (round(sqrt(nrow(EDR.g2))), (2*(round(sqrt(nrow(EDR.g2))))),
                        by=round(sqrt(nrow(EDR.g2))/10)) 
 k.g1.range; k.g2.range 
 
 #Step 6: K value range estimation with dedicated function
 vk.g1<-validation_kproto(method = "silhouette", object = NULL, data =  
                EDR.g1[,EDR.g1.cols], k=k.g1.range, lambda = lbd.g1 , kp_obj = 'optimal', verbose=FALSE)
 vk.g1$k_opt  #for group G1=40
 vk.g2<-validation_kproto(method = "silhouette", object = NULL, data = EDR.g2[,EDR.g2.cols], k=k.g2.range, lambda = lbd.g2 , kp_obj = 'optimal', verbose = FALSE)
 vk.g2$k_opt #for group G2=84
 
# 4) K-PROTOTYPES RUN  ############################################################################################
 #example with explicitly stated column names, selected k value and lambda - values selected by hand
 #kproto(EDR.g1[,c ("TARIFF","RATE_OFFER","EVENT_TYPE", "EVENT_TYPE_GROUP", "IS_INT", "AMOUNT", "VOLUME","ROUNDED_VOLUME", "UNITS", "UNIT_RATE", "CHARGE", "CMP_RESULTS")],  k = 36 , lambda=24434.31)       
 
 #run Clust prototypes with the parameters estimated in previous steps and store results to variables k.g1 a k.g2:
 start_time <- Sys.time()
 k.g1<-kproto(EDR.g1[,EDR.g1.cols], k = vk.g1$k_opt , lambda=lbd.g1)  #reduced to 29
 start_time; Sys.time();  Sys.time()-start_time #2.6min 
 nrow (EDR.g1) ; length (EDR.g1.cols) #27k rows, 14 cols
 
 start_time <- Sys.time()
 k.g2<-kproto(EDR.g2[,EDR.g2.cols], k = vk.g2$k_opt , lambda=lbd.g2)  #reduced to 70
 start_time; Sys.time();  Sys.time()-start_time 
 nrow (EDR.g2) ; length (EDR.g2.cols) 

# 5) K-PROTOTYPES RESULTS PROCESS ###################################################################################
 #Distances and groups connect to data - get distances for each row to its group center
 EDR.g1.dist<-apply(data.frame(k.g1$dists), 1, FUN = min) 
 EDR.g2.dist<-apply(data.frame(k.g2$dists), 1, FUN = min)
 
 #join new column to EDR.gX, give it a name clust and content the cluster with prefix G1_ / G2_
 EDR_CLUST<-rbind (
    cbind (EDR.g1, clust=paste0( "G1_",k.g1$cluster ), clust_dist= EDR.g1.dist) ,
    cbind (EDR.g2, clust=paste0( "G2_",k.g2$cluster ), clust_dist= EDR.g2.dist) 
 )
 #head(EDR_CLUST)

# 6) NN DATASET PREPARE #############################################################################################
 #6.1 - model matrix - replicate categorical columns
 EDR.g1.mm<-model.matrix( ~ CMP_RESULTS + UNIT_RATE + RATE_OFFER + EVENT_TYPE  ,  data = EDR.g1 )  #for data zone and direction is not populated
 EDR.g2.mm<-model.matrix( ~ CMP_RESULTS + UNIT_RATE + RATE_OFFER + EVENT_TYPE + CALL_ZONE + CALL_DIRECTION ,  data = EDR.g2 )
 #head(EDR.g2.mm) #replicated categorical columns, for each value type - have 1 or 0
 
 #6.2 Format matrix to dataframe (neuralnet needs dataframe)
 EDR.g1.mm.df<-data.frame(EDR.g1.mm)
 EDR.g2.mm.df<-data.frame(EDR.g2.mm)
 
 #6.3 how many New is in each group?
 nrow(filter(EDR.g1.mm.df, CMP_RESULTSNew == 1) )   #have 0  new in group 1
 nrow(filter(EDR.g2.mm.df, CMP_RESULTSNew == 1) )   #have 16 new in group 2
 
 #6.3 train dataset (those which are same)
 EDR.g1.mm.df.same<-filter(EDR.g1.mm.df, CMP_RESULTSSame == "1") 
 EDR.g2.mm.df.same<-filter(EDR.g2.mm.df, CMP_RESULTSSame == "1") 
 
 #6.4. remove columns, which are were created by model.matrix and are not needed (without them the prediction is more exact)
 EDR.g1.mm.df.same.flt<-EDR.g1.mm.df.same     #create a copy of object 
 EDR.g1.mm.df.same.flt$X.Intercept.    <-NULL #remove intercept col
 EDR.g1.mm.df.same.flt$CMP_RESULTSNew  <-NULL #remove status col
 EDR.g1.mm.df.same.flt$CMP_RESULTSSame <-NULL #remove status col
 
 EDR.g2.mm.df.same.flt<-EDR.g2.mm.df.same     #create a copy of object 
 EDR.g2.mm.df.same.flt$X.Intercept.    <-NULL #remove intercept col
 EDR.g2.mm.df.same.flt$CMP_RESULTSNew  <-NULL #remove status col
 EDR.g2.mm.df.same.flt$CMP_RESULTSSame <-NULL #remove status col
 
# 7) NN TRAIN MODEL ##############################################################################################
 library(neuralnet)
 nn.g1<-neuralnet(UNIT_RATE ~ .  ,
                  data=EDR.g1.mm.df.same.flt, hidden = 5 ) 
 #alternatives: c(10,5,3), threshold=0.01), stepmax=1e+03, learningrate=NULL) 
 plot (nn.g1) #show model of data
 
 nn.g2<-neuralnet(UNIT_RATE ~ .  ,
               data=EDR.g2.mm.df.same.flt, hidden = 5 )
 #alternatives: c(10,5,3), threshold=0.01), stepmax=1e+03, learningrate=NULL) 
 plot (nn.g2) #show model of voice

 ?neuralnet 
# 8) NN COMPUTE VALUES BASED ON MODEL ############################################################################################## 
 nn.g1.res<-round(compute(nn.g1, EDR.g1.mm.df)$net.result,2)  #compute for each from the group g1 and round it
 nn.g2.res<-round(compute(nn.g2, EDR.g2.mm.df)$net.result,2)  #compute for each from the group g2 and round it
 
 #show examples on new
 #UNIT_RATE_NN_DIFF_PCT<-100*round ((EDR_CLUST_NN$UNIT_RATE_NN-EDR_CLUST_NN$UNIT_RATE)/EDR_CLUST_NN$UNIT_RATE,2) 
 # UNIT_RATE_NN_DIFF<- (EDR_CLUST_NN$UNIT_RATE_NN-EDR_CLUST_NN$UNIT_RATE)
 #filter( cbind (EDR.g2, UNIT_RATE_NN=nn.g2.res, UNIIT_RATE_DIFF=EDR.g2$UNIT_RATE-nn.g2.res), CMP_RESULTS =="New") [,c("RATE_OFFER","EVENT_TYPE", "UNIT_RATE", "UNIT_RATE_NN", "UNIIT_RATE_DIFF")]

# 9) join new NN column with estimations to the dataset 
 EDR_CLUST_NN<-rbind (
   cbind (EDR.g1, clust=paste0( "G1_",k.g1$cluster ), CLUST_DIST= EDR.g1.dist, UNIT_RATE_NN=nn.g1.res ) ,
   cbind (EDR.g2, clust=paste0( "G2_",k.g2$cluster ), CLUST_DIST= EDR.g2.dist, UNIT_RATE_NN=nn.g2.res ) 
 )
 
 #fill the diffs between unit rate and estimated unit_rate_nn to new column
 #EDR_CLUST_NN$UNIT_RATE_NN_DIFF_PCT<-100*round ((EDR_CLUST_NN$UNIT_RATE_NN-EDR_CLUST_NN$UNIT_RATE)/EDR_CLUST_NN$UNIT_RATE,2)
 EDR_CLUST_NN$UNIT_RATE_NN_DIFF<-(EDR_CLUST_NN$UNIT_RATE_NN-EDR_CLUST_NN$UNIT_RATE)
 
 #show stats 
 #filter(EDR_CLUST_NN, CMP_RESULTS == "New") [,c("RATE_OFFER","EVENT_TYPE", "UNIT_RATE", "UNIT_RATE_NN","UNIT_RATE_NN_DIFF")]

# 10) stats on nn
 EDRs<- EDR_CLUST_NN
 AllTOT <-nrow (EDRs) 
 AllOK  <-nrow (EDRs[ (EDRs$UNIT_RATE_NN_DIFF == 0) , ]) 
 AllNOK <-nrow (EDRs[ (EDRs$UNIT_RATE_NN_DIFF != 0) , ]) 
 SameTOT <-nrow (EDRs[ (EDRs$CMP_RESULTS=="Same" ) , ]) 
 SameOK  <-nrow (EDRs[ (EDRs$CMP_RESULTS=="Same" & EDRs$UNIT_RATE_NN_DIFF == 0) , ]) 
 SameNOK <-nrow (EDRs[ (EDRs$CMP_RESULTS=="Same" & EDRs$UNIT_RATE_NN_DIFF != 0) , ]) 
 NewTOT  <-nrow (EDRs[ (EDRs$CMP_RESULTS=="New" ) , ]) 
 NewOK   <-nrow (EDRs[ (EDRs$CMP_RESULTS=="New" & EDRs$UNIT_RATE_NN_DIFF == 0) , ]) 
 NewNOK  <-nrow (EDRs[ (EDRs$CMP_RESULTS=="New" & EDRs$UNIT_RATE_NN_DIFF != 0) , ]) 
 DiffTOT <-nrow (EDRs[ (EDRs$CMP_RESULTS=="Diff" ) , ]) 
 DiffOK  <-nrow (EDRs[ (EDRs$CMP_RESULTS=="Diff" & EDRs$UNIT_RATE_NN_DIFF == 0) , ]) 
 DiffNOK <-nrow (EDRs[ (EDRs$CMP_RESULTS=="Diff" & EDRs$UNIT_RATE_NN_DIFF != 0) , ]) 
 
 rbind(
   sprintf("successfully estimated overall: %10d out of: %10d which is: %4d %% ", AllOK, AllTOT, round (AllOK/AllTOT,2) *100 ),
   sprintf("successfully estimated Same:    %10d out of: %10d which is: %4d %% ", SameOK, SameTOT, round (SameOK/SameTOT,2) *100 ),
   sprintf("successfully estimated Diff:    %10d out of: %10d which is: %4d %% ", DiffOK, DiffTOT, round (DiffOK/DiffTOT,2) *100 ),
   sprintf("successfully estimated New:     %10d out of: %10d which is: %4d %% ", NewOK, NewTOT, round (NewOK/NewTOT,2) *100 )
 )  
 
 #[1,] "successfully estimated overall:       3536 out of:       4336 which is:   82 % "
 #[2,] "successfully estimated Same:          3520 out of:       3952 which is:   89 % "
 #[3,] "successfully estimated Diff:             0 out of:        368 which is:    0 % "
 #[4,] "successfully estimated New:             16 out of:         16 which is:  100 % "
 
#####validate on samples
 filter(EDRs, CMP_RESULTS == "Same" )  [,c("RATE_OFFER","EVENT_TYPE", "UNIT_RATE", "UNIT_RATE_NN", "CMP_DETAILS", "UNIT_RATE_NN_DIFF")]
 filter(EDRs, (CMP_RESULTS == "Same" & UNIT_RATE_NN_DIFF != 0 ) )  [,c("RATE_OFFER","EVENT_TYPE", "UNIT_RATE", "UNIT_RATE_NN", "UNIT_RATE_NN_DIFF")]

 filter(EDRs, CMP_RESULTS == "Diff" )  [,c("RATE_OFFER","EVENT_TYPE", "UNIT_RATE", "UNIT_RATE_NN", "CMP_DETAILS", "UNIT_RATE_NN_DIFF")]
 filter(EDRs, (CMP_RESULTS == "Diff" & UNIT_RATE_NN_DIFF != 0 ) )  [,c("RATE_OFFER","EVENT_TYPE", "UNIT_RATE", "UNIT_RATE_NN", "UNIT_RATE_NN_DIFF")]

 filter(EDRs, CMP_RESULTS == "New") [,c("RATE_OFFER","EVENT_TYPE", "UNIT_RATE", "UNIT_RATE_NN", "UNIT_RATE_NN_DIFF")]
 filter(EDRs, (CMP_RESULTS == "New" & UNIT_RATE_NN_DIFF_PCT != 0 ) )  [,c("RATE_OFFER","EVENT_TYPE", "UNIT_RATE", "UNIT_RATE_NN", "UNIT_RATE_NN_DIFF")]
 

# 11) UPLOAD DATA BACK TO DB ########################################################################################
 #function dbWriteTable doesn't support NA string. This step replaces all NA strings with ??????
 EDR_CLUST_NN[is.na(EDR_CLUST_NN)] = ""
 
 #store the data to DB
 start_time <- Sys.time()
 dbWriteTable(jdbcConnection, "EVENT_NEW_CLUST", EDR_CLUST_NN, rownames=FALSE, overwrite = TRUE, append = FALSE)
 Sys.time()-start_time #show time stats
 
 #check the data are in DB
  dbGetQuery(jdbcConnection, "select count(*) from EVENT_NEW_CLUST ") #4336
 

 