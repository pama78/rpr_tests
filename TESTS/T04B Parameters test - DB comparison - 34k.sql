--analysis - input tables
  set linesize 200
  SELECT * FROM pricelist;
  SELECT count (*) FROM event_old;
  SELECT count (*) FROM event_new;

--example - compare old and new run, only for the equality of one of the columns (Charge), just one example
  SELECT count(*)
  FROM EVENT_OLD old, EVENT_NEW new
  WHERE new.event_id = old.event_id AND old.charge != new.charge;   

--Oracle comparison
  --establish new columns for comparison reasons
  --mark rows with same values with marker – populate cmp_results, cmp_diff, cmp_details 130k =
  set serveroutput on ;
  DECLARE
    retVal VARCHAR2(400);
    k_date VARCHAR2(30);  
  BEGIN
   select to_char(sysdate, 'YYYYMMDD HH24:MI:SS') into k_date from dual;
   DBMS_OUTPUT.PUT_LINE('Started doOraCompare* functions at: ' || k_date );
   --
   retVal := doOraCompareInit();
   select to_char(sysdate, 'YYYYMMDD HH24:MI:SS') into k_date from dual;
   DBMS_OUTPUT.put_line('doOraCompareInit ended with status: ' || retVal || ' Finished at: ' || k_date);
   --
   retVal := doOraCompareRows();
   select to_char(sysdate, 'YYYYMMDD HH24:MI:SS') into k_date from dual;
   DBMS_OUTPUT.put_line('doOraCompareRows - row level: ' || retVal || ' Finished at: ' || k_date);
   commit;
   --
   retVal := doOraCompareDetails ();
   select to_char(sysdate, 'YYYYMMDD HH24:MI:SS') into k_date from dual;
   DBMS_OUTPUT.put_line('doOraCompareDetails - detail level: ' || retVal || ' Finished at:' || k_date);
   commit;
   --
   DBMS_OUTPUT.PUT_LINE('Ended doOraCompare: ' || k_date );
END;
/

--9min for 36k rows, 3k diffs
--Started doOraCompare* functions at: 20211226 22:35:23
--doOraCompareInit ended with status: Columns cmp_results, cmp_diff, cmp_details initialized. Indexes EVENT_NEW_IX, EVENT_OLD_IX exist Finished at: 20211226 22:35:24
--doOraCompareRows - row level: Diff=2888; New=16; Same=31672 Finished at: 20211226 22:35:25
--doOraCompareDetails - detail level: All diffs=2888; Groups in cmp_diff=5; Subgroups by cmp_details value=26 Finished at:20211226 22:44:10
--Ended doOraCompare: 20211226 22:44:10


--Show statistics    
set linesize 200
set pagesize 100
column cmp_results format A10
column cmp_diff format A30
column cmp_details format A90
SELECT cmp_results, cmp_diff, cmp_Details, COUNT (*) FROM EVENT_NEW GROUP BY cmp_results , cmp_diff, cmp_Details;

--CMP_RESULT CMP_DIFF                       CMP_DETAILS                                                                                  COUNT(*)
------------ ------------------------------ ------------------------------------------------------------------------------------------ ----------
--New                                                                                                                                          16
--Diff       unit_rate;                     unit_rate(.5->.45);                                                                                96
--Diff       unit_rate;                     unit_rate(200->170);                                                                               96
--Diff       unit_rate;charge;              unit_rate(4->5);charge(.08->.1);                                                                    1
--Diff       unit_rate;charge;              unit_rate(5->6);charge(.1->.12);                                                                    1
--Diff       unit_rate;charge;              unit_rate(.5->.45);charge(1->.9);                                                                  96
--Diff       unit_rate;charge;              unit_rate(.5->.45);charge(3->2.7);                                                                 96
--Diff       unit_rate;charge;              unit_rate(.5->.45);charge(.5->.45);                                                               672
--Diff       unit_rate;charge;              unit_rate(.5->.45);charge(.49->.44);                                                               96
--Diff       unit_rate;charge;              unit_rate(.5->.45);charge(.53->.47);                                                              192
--Diff       unit_rate;charge;              unit_rate(.5->.45);charge(1.03->.92);                                                             192
--Diff       unit_rate;charge;              unit_rate(.5->.45);charge(1.5->1.35);                                                              96
--Diff       unit_rate;charge;              unit_rate(200->170);charge(12->10.2);                                                             288
--Diff       unit_rate;charge;              unit_rate(200->170);charge(24->20.4);                                                              96
--Diff       unit_rate;charge;              unit_rate(200->170);charge(66->56.1);                                                              96
--Diff       unit_rate;charge;              unit_rate(3.5->4.5);charge(.07->.09);                                                               1
--Diff       unit_rate;charge;              unit_rate(.5->.45);charge(2.81->2.53);                                                            192
--Diff       rate_offer;unit_rate;          rate_offer(Balicek B1->Tarif TA);unit_rate(180->170);                                              95
--Diff       rate_offer;unit_rate;          rate_offer(Balicek B1->Tarif TA);unit_rate(180->177);                                               1
--Diff       call_zone;unit_rate;charge;    call_zone(2->3);unit_rate(15->20);charge(.3->.4);                                                   1
--Diff       call_zone;unit_rate;charge;    call_zone(3->4);unit_rate(25->30);charge(.5->.6);                                                   1
--Diff       call_zone;unit_rate;charge;    call_zone(2->3);unit_rate(14->19);charge(.28->.38);                                                 1
--Diff       call_zone;unit_rate;charge;    call_zone(0->2);unit_rate(1.5->8.5);charge(1.47->8.33);                                             1
--Diff       call_zone;unit_rate;charge;    call_zone(0->2);unit_rate(3.5->10.5);charge(3.43->10.29);                                           1
--Diff       rate_offer;unit_rate;charge;   rate_offer(Balicek B1->Tarif TA);unit_rate(180->170);charge(10.8->10.2);                          288
--Diff       rate_offer;unit_rate;charge;   rate_offer(Balicek B1->Tarif TA);unit_rate(180->170);charge(21.6->20.4);                           96
--Diff       rate_offer;unit_rate;charge;   rate_offer(Balicek B1->Tarif TA);unit_rate(180->170);charge(59.4->56.1);                           96
--Same       NA                             NA                                                                                              31672
--28 rows selected.

