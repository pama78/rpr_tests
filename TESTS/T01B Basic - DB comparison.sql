--analysis - input tables
  SELECT * FROM pricelist;
  SELECT count (*) FROM event_old;
  SELECT count (*) FROM event_new;

--example - compare old and new run, only for the equality of one of the columns (Charge), just one example
  SELECT *
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

-- STATS
--Started doOraCompare* functions at: 20211129 12:08:27
--doOraCompareInit ended with status: Columns cmp_results, cmp_diff, cmp_details initialized. Indexes EVENT_NEW_IX, EVENT_OLD_IX exist Finished at: 20211129 12:08:28
--doOraCompareRows - row level: Diff=360; Same=3960 Finished at: 20211129 12:08:28
--doOraCompareDetails - detail level: All diffs=360; Groups in cmp_diff=4; Subgroups by cmp_details value=17 Finished at:20211129 12:09:43
--Ended doOraCompare: 20211129 12:09:43 


--Show statistics    
set linesize 200
column cmp_results format A10
column cmp_diff format A30
column cmp_details format A90

SELECT cmp_results, cmp_diff, cmp_Details, COUNT (*) FROM EVENT_NEW GROUP BY cmp_results , cmp_diff, cmp_Details;
--Diff	unit_rate;	unit_rate(.5->.45);	                        12
--Diff	unit_rate;	unit_rate(200->170);        	            12
--Diff	unit_rate;charge;	unit_rate(.5->.45);charge(1->.9);	12
--Diff	unit_rate;charge;	unit_rate(.5->.45);charge(3->2.7);	12
--Diff	unit_rate;charge;	unit_rate(.5->.45);charge(.5->.45);	84
--Diff	unit_rate;charge;	unit_rate(.5->.45);charge(.49->.44);12
--Diff	unit_rate;charge;	unit_rate(.5->.45);charge(.53->.47);	24
--Diff	unit_rate;charge;	unit_rate(.5->.45);charge(1.03->.92);	24
--Diff	unit_rate;charge;	unit_rate(.5->.45);charge(1.5->1.35);	12
--Diff	unit_rate;charge;	unit_rate(200->170);charge(12->10.2);	36
--Diff	unit_rate;charge;	unit_rate(200->170);charge(24->20.4);	12
--Diff	unit_rate;charge;	unit_rate(200->170);charge(66->56.1);	12
--Diff	unit_rate;charge;	unit_rate(.5->.45);charge(2.81->2.53);	24
--Diff	rate_offer;unit_rate;	rate_offer(Balicek B1->Tarif TA);unit_rate(180->170);	12
--Diff	rate_offer;unit_rate;charge;	rate_offer(Balicek B1->Tarif TA);unit_rate(180->170);charge(10.8->10.2);	36
--Diff	rate_offer;unit_rate;charge;	rate_offer(Balicek B1->Tarif TA);unit_rate(180->170);charge(21.6->20.4);	12
--Diff	rate_offer;unit_rate;charge;	rate_offer(Balicek B1->Tarif TA);unit_rate(180->170);charge(59.4->56.1);	12
--Same	NA	NA	3960
