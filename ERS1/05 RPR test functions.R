############################################
# Script : Functions for RPR analysis in R
# Purpose: Flow of cluster analysis on the practical example
# 
# 1) naCount 
#    internal function for empty columns detection
# 2) doImportAndPrepareData 
#    detects nulls in data, split to groups, prepare G1 and G2
# 3) kproto_NN_execute (testing function for stress tests)
#    runs kproto, prepares data for NN, runs NN, merge data and store to DB
############################################


#Function for counting empty (NA) values
 naCount <- function(x){
    list( sum(is.na(x))  , sum(!is.na(x)) )
 }


#function for import data
doImportAndPrepareData <- function(){
 colsFactor<<-c("CUSTOMER_ID","CUSTOMER_DETAILS","TARIFF","RATE_OFFER","EVENT_TYPE","CALL_ZONE", "IS_INT","EVENT_TYPE_GROUP","CALL_DIRECTION","CMP_RESULTS","CMP_DIFF","CMP_DETAILS")

 #Step 1 : reopen connection, in case it is not available
 jdbcConnection =dbConnect(jdbcDriver, paste0("jdbc:oracle:thin:@//",DB_INST), DB_USER , DB_PASS)
 
 #Step 2 : import data to object EDR
 start_time <- Sys.time()
 EDR<<-dbReadTable(jdbcConnection,'EVENT_NEW')
 load_dur <- Sys.time()-start_time
 load_cnt <- nrow(EDR)

 #Step 3 : cols to factors, EDR split (valid for the current system behavior. Other will have different columns and groups of data)
 EDR[,colsFactor] <- lapply(EDR[,colsFactor], factor )  
 EDR.g1<<-EDR[is.na(EDR$ROUNDED_DURATION ),]    #group 1, where rounded_duration is empty
 EDR.g2<<-EDR[!is.na(EDR$ROUNDED_DURATION ),]   #group 2, all the rest
 load_cnt.g1<<-nrow(EDR.g1) 
 load_cnt.g2<<-nrow(EDR.g2) 

 #Step 4 : store all other columns to variable EDR.g1.cols, and exclude identification details (excluded first three - "EVENT_ID", "CUSTOMER_ID", "CUSTOMER_DETAILS")
 EDR.g1.cols<<-names(which(colSums(is.na(EDR.g1)) == 0))[-c(1:3)]  
 EDR.g2.cols<<-names(which(colSums(is.na(EDR.g2)) == 0))[-c(1:3)]  

 #Step 5 : Lambda estimation 
 lbd.g1  <<- lambdaest(EDR.g1[,EDR.g1.cols])  # 24409.62  
 lbd.g2  <<- lambdaest(EDR.g2[,EDR.g2.cols])  # 12962.03  
 
 print ("==========================================================================" )
 print ("group 1 cols:")
 print (EDR.g1.cols )
 print ("group 2 cols:")
 print ( EDR.g2.cols )
 print (paste ("imported to EDR:", load_cnt, ", group 1: ", load_cnt.g1, ", group 2: ",  load_cnt.g2 ))
 print (paste ("lambdaest g1: ", lbd.g1, " lambdaest g2: ", lbd.g2))
 print (paste ("duration: ",   Sys.time() - start_time  ))
 print ("==========================================================================" )
}


 kproto_NN_execute <- function(g1_k, g2_k, g1_l,g2_l, g1_cols, g2_cols, g1_hidden, g2_hidden)
 {
  #Step 1 : run k-Prototypes twice - once per each group
    time0 <- Sys.time()
    print (paste ("# phase 1 # k-Prototypes (G1) started at: ", time0  ))
    k.g1<-kproto(EDR.g1[,g1_cols], k = g1_k , lambda=g1_l)  #estimated k=100
    print (paste ("# phase 1 # k-Prototypes (G2) started at: ", Sys.time()  ))
    k.g2<-kproto(EDR.g2[,g2_cols], k = g2_k , lambda=g2_l)  #estimated k=100
    EDR.g1.dist<-apply(data.frame(k.g1$dists), 1, FUN = min) 
    EDR.g2.dist<-apply(data.frame(k.g2$dists), 1, FUN = min)
    time1<-Sys.time();  phase1.dur<-time1-time0    
    print (paste0 ("# phase 1 # k-Prototypes (G1+G2) ended after: ", phase1.dur ))

  #Step 2 : NN - Prepare datasets (group 1+2)
    print (paste ("# phase 2a1 # NN (matrix+df G1) started at: ", time1  ))
    EDR.g1.mm.df<-data.frame(model.matrix( ~ CMP_RESULTS + UNIT_RATE + RATE_OFFER + EVENT_TYPE  ,  data = EDR.g1 ))
    EDR.g1.mm.df.same<-filter(EDR.g1.mm.df, CMP_RESULTSSame == "1")   #train G1
    EDR.g1.mm.df.same.flt<-EDR.g1.mm.df.same     #create a copy of object 
    EDR.g1.mm.df.same.flt$X.Intercept.    <-NULL #remove intercept col
    EDR.g1.mm.df.same.flt$CMP_RESULTSNew  <-NULL #remove status col
    EDR.g1.mm.df.same.flt$CMP_RESULTSSame <-NULL #remove status col
    time2<-Sys.time();  phase2a1.dur<-time2-time1
    print (paste0 ("# phase 2a1 # ended after: ", phase2a1.dur ))
  
    print (paste ("# phase 2a2 # NN (matrix+df G2) started at: ", time2  ))
    EDR.g2.mm.df<-data.frame(model.matrix( ~ CMP_RESULTS + UNIT_RATE + RATE_OFFER + EVENT_TYPE + CALL_ZONE + CALL_DIRECTION ,  data = EDR.g2 ))
    EDR.g2.mm.df.same<-filter(EDR.g2.mm.df, CMP_RESULTSSame == "1")   #train G2
    EDR.g2.mm.df.same.flt<-EDR.g2.mm.df.same     #create a copy of object 
    EDR.g2.mm.df.same.flt$X.Intercept.    <-NULL #remove intercept col
    EDR.g2.mm.df.same.flt$CMP_RESULTSNew  <-NULL #remove status col
    EDR.g2.mm.df.same.flt$CMP_RESULTSSame <-NULL #remove status col
    time3<-Sys.time();  phase2a2.dur<-time3-time2
    print (paste0 ("# phase 2a2 # ended after: ", phase2a2.dur ))

   #Step 3 : NN - train
   #alternatives: learningrate=0.00001)  , stepmax=1e5, hidden= c(10,5,3) ) , threshold=0.01,  stepmax = 1e+03 ...
    print (paste ("# phase 2b1 # NN (model prepare G1) started at: ", time3  ))
    nn.g1<<-neuralnet(UNIT_RATE ~ .  ,
                  data=EDR.g1.mm.df.same.flt, hidden = g1_hidden, algorithm='rprop+') 
    time4<-Sys.time();  phase2b1.dur<-time4-time3
    print (paste0 ("# phase 2b1 # ended after: ", phase2b1.dur ))

    print (paste ("# phase 2b2 # NN (model prepare G2) started at: ", time4  ))
    nn.g2<<-neuralnet(UNIT_RATE ~ .  ,
               data=EDR.g2.mm.df.same.flt, hidden = g2_hidden, algorithm='rprop+') # , learningrate=0.00001) # ,stepmax=1e5 )
    time5<-Sys.time();  phase2b2.dur<-time5-time4
    print (paste0 ("# phase 2b2 # ended after: ", phase2b2.dur ))

  #Step 4 : NN - execute
    print (paste ("# phase 2c1 # NN (estimate) started at: ", time5  ))
    nn.g1.res<-round(compute(nn.g1, EDR.g1.mm.df)$net.result,2)  #compute for each from the group g1 and round it
    time6<-Sys.time();  phase2c1.dur<-time6-time5
    print (paste0 ("# phase 2c # ended after: ", phase2c1.dur ))

    print (paste ("# phase 2c2 # NN (estimate) started at: ", time5  ))
    nn.g2.res<-round(compute(nn.g2, EDR.g2.mm.df)$net.result,2)  #compute for each from the group g2 and round it
    time7<-Sys.time();  phase2c2.dur<-time7-time6
    print (paste0 ("# phase 2c2 # ended after: ", phase2c2.dur ))

  #Step 5 : Merge results 
    print (paste ("# phase 3 # Merge data and store do DB started at: ", time7  ))   
    EDR_CLUST_NN<<-rbind (
     cbind (EDR.g1, clust=paste0( "G1_",k.g1$cluster ), CLUST_DIST= EDR.g1.dist, UNIT_RATE_NN=nn.g1.res ) ,
     cbind (EDR.g2, clust=paste0( "G2_",k.g2$cluster ), CLUST_DIST= EDR.g2.dist, UNIT_RATE_NN=nn.g2.res ) 
    )
   EDR_CLUST_NN$UNIT_RATE_NN_DIFF<<-(EDR_CLUST_NN$UNIT_RATE_NN-EDR_CLUST_NN$UNIT_RATE)
   EDR_CLUST_NN[is.na(EDR_CLUST_NN)] = "" #workaround for DB upload issue with null values
 
  #Step 6 : and store to DB
   #db connection, if lost
   jdbcDriver =JDBC("oracle.jdbc.OracleDriver",classPath= DB_JDBC)
   jdbcConnection =dbConnect(jdbcDriver, paste0("jdbc:oracle:thin:@//",DB_INST), DB_USER , DB_PASS)
   
   #clean table
   dbSendUpdate(jdbcConnection, "truncate table EVENT_NEW_CLUST")
   dbGetQuery(jdbcConnection, "  select count (*) from EVENT_NEW_CLUST " )
   
   #store the data to DB (<100k, disabled)
   #dbWriteTable(jdbcConnection, "EVENT_NEW_CLUST", EDR_CLUST_NN, rownames=FALSE, overwrite = TRUE, append = FALSE)   #is OK for <100k rows

   #store the data to DB by bulks (>100k)
   max <- nrow(EDR_CLUST_NN) ;   low<-1;   impOverwrite<-TRUE; impAppend<-FALSE #initialize vars for first iterration, to create table
   while (low < max) {
     high<-low+100000
      if (low>1) {
        impOverwrite<-FALSE
        impAppend<-TRUE
      }
   print ( paste0 ('importing to DB range: ', low ,":" , min (high -1 , max)  ))
   dbWriteTable(jdbcConnection, "EVENT_NEW_CLUST", EDR_CLUST_NN[low:min (high-1 , max),], rownames=FALSE, overwrite = impOverwrite, append = impAppend)
   low<-high
   } 

   time8<-Sys.time();  phase3.dur<-time8-time7
   print (paste0 ("# phase 3 # ended after: ", phase3.dur ))
 
   #check the data are in DB
   EDR.DB.cnt<-dbGetQuery(jdbcConnection, "select count(*) from EVENT_NEW_CLUST ") #4336
   print (paste0 ("count in DB:" , EDR.DB.cnt ))

  #Step 7 : get results, and print
   res<-t(dbGetQuery(jdbcConnection, "  select event_id from EVENT_NEW_CLUST where event_id in  (select event_id from  (
     SELECT event_id, cmp_results, cmp_diff, cmp_details, clust, round (clust_dist,2)
     FROM EVENT_NEW_CLUST WHERE event_id IN
     ( ( SELECT MIN(event_id)  KEEP (DENSE_RANK FIRST ORDER BY clust, clust_dist)
         FROM EVENT_NEW_CLUST WHERE  cmp_results='Diff'   GROUP BY clust,cmp_diff)
         UNION
         ( SELECT MAX(event_id)  KEEP (DENSE_RANK LAST ORDER BY clust, clust_dist)
           FROM EVENT_NEW_CLUST WHERE  cmp_results='Diff'   GROUP BY clust,cmp_diff) )  ) ) and event_id in (2,3,4,5,6,7,10,11,12)" ) )

   candidates<-(dbGetQuery(jdbcConnection, "  select count (*) from EVENT_NEW_CLUST where event_id in  (select event_id from  (
     SELECT event_id, cmp_results, cmp_diff, cmp_details, clust, round (clust_dist,2)
     FROM EVENT_NEW_CLUST WHERE event_id IN
     ( ( SELECT MIN(event_id)  KEEP (DENSE_RANK FIRST ORDER BY clust, clust_dist)
         FROM EVENT_NEW_CLUST WHERE  cmp_results='Diff'   GROUP BY clust,cmp_diff)
         UNION
         ( SELECT MAX(event_id)  KEEP (DENSE_RANK LAST ORDER BY clust, clust_dist)
           FROM EVENT_NEW_CLUST WHERE  cmp_results='Diff'   GROUP BY clust,cmp_diff) )  ) ) " ) )

    #serialize lists for print
    g1_lp<-paste0(g1_l, collapse="," )
    g2_lp<-paste0(g2_l, collapse="," )
    g1_cols_p<-paste0(g1_cols, collapse="," )
    g2_cols_p<-paste0(g2_cols, collapse="," )

    #print results
    print ("==========================================================================" )
    print ( paste ("params: g1_k:" , g1_k, " g2_k: ", g2_k ,"g1_l: ", g1_lp, " g2_l: " , g2_lp) )
    print ( paste0 ( "g1_cols: ", g1_cols_p ))
    print ( paste0 ( "g2_cols: ", g2_cols_p ))
    print ("==========================================================================" )
    print ( paste0 ("Artificial error detection analysis. for K(1):", g1_k," K(2):", g2_k, " lambda(1):",  g1_lp,  " lambda(2):", g2_lp ))
    print ( paste0 ("Suggested candidates for manual validation: ", candidates ))
    print ( paste0 ("Which artificial errors got to selection out of 9 (event_ids: 2,3,4,5,6,7,10,11,12)?: " ))
    print ( res ) 

    print (paste0 ("cols in G1 matrix: ", ncol(EDR.g1.mm.df.same.flt), "cols in G2 matrix: ", ncol(EDR.g2.mm.df.same.flt) ))
    print (paste0 ("rows in G1 matrix: ", nrow(EDR.g1.mm.df.same.flt), "rows in G2 matrix: ", nrow(EDR.g2.mm.df.same.flt) ))
    print (paste ("k-Prototypes duration from: ",time0, " to: ", time1, " (", time1 - time0 , " ) " ))
    print (paste ("NN duration from: "          ,time1, " to: ", time7, " (", time7 - time1 , " ) " ))
    print (paste ("DB store duration from: "    ,time7, " to: ", time8, " (", time8 - time7 , " ) " ))
    print (paste ("overall duration: "          ,time8 - time0 ))
    print ("==========================================================================" )
 
}


