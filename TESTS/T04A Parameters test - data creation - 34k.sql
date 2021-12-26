-------------------------------------------------
--Step 1: insert prices to pricelist
-------------------------------------------------
  delete pricelist;
  Insert into PRICELIST (ID, NAME, TYPE, V_ONN, V_OFN, V_Z1_O, V_Z1_I, V_Z2_O, V_Z2_I, V_Z3_O, V_Z3_I, SMS, DATA)
   Values (100, 'Tarif TA', 'T', 1.5, 3.5,  5, 4, 15, 14, 25,  24, 1.8, 200);
  Insert into PRICELIST (ID, NAME, TYPE, V_ONN, V_OFN, V_Z1_O, V_Z1_I, V_Z2_O, V_Z2_I, V_Z3_O, V_Z3_I, SMS, DATA)
   Values (101, 'Tarif TB', 'T', 1, 2.5, 4, 3, 14, 13, 24, 23, 1.5, 150);
  Insert into PRICELIST (ID, NAME, TYPE, V_ONN, V_OFN, V_Z1_O, V_Z1_I, V_Z2_O, V_Z2_I, V_Z3_O, V_Z3_I, SMS, DATA)
   Values (102, 'Tarif TC', 'T', 0.5, 1.5, 3, 2, 13, 12, 23, 22, 1, 100);
  Insert into PRICELIST (ID, NAME, TYPE, TAR_DUR_MIN, TAR_DUR_RND) 
   Values (103, 'Tarifikace T1 1+1', 'R', 1, 1);
  Insert into PRICELIST (ID, NAME, TYPE, TAR_DUR_MIN, TAR_DUR_RND)
   Values (104, 'Tarifikace T2 60+60', 'R', 60, 60);
  Insert into PRICELIST (ID, NAME, TYPE, TAR_DUR_MIN, TAR_DUR_RND)
   Values (105, 'Tarifikace T3 60+1', 'R', 60, 1);
  Insert into PRICELIST (ID, NAME, TYPE, SMS, DATA)
   Values (106, 'Balicek B1', 'A', 0.5, 180);
  Insert into PRICELIST (ID, NAME, TYPE, V_ONN, V_OFN)
   Values (107, 'Balicek B2', 'A', 0.3, 0.8);
  Insert into PRICELIST (ID, NAME, TYPE, V_Z1_O, V_Z1_I)
   Values (108, 'Balicek B3', 'A', 0.5, 1.8);
  --
  Insert into PRICELIST (ID, NAME, TYPE, V_Z1_O, V_Z1_I)
   Values (109, 'Balicek B4', 'A', 2.2, 2.2);
  Insert into PRICELIST (ID, NAME, TYPE, V_Z1_O, V_Z1_I)
   Values (110, 'Balicek B5', 'A', 3.3, 3.3);
  Insert into PRICELIST (ID, NAME, TYPE, V_Z3_O, V_Z3_I)
   Values (111, 'Balicek B6', 'A', 24.5, 23.8);
 commit;

--validation
 set linesize 200
 select * from PRICELIST ;

-------------------------------------------------
--Step 2: create customers according to pricelist 
-------------------------------------------------
set serveroutput on ;
DECLARE    
   res number;    
BEGIN    
   res := createCustByPricelist ();    
   dbms_output.put_line('Created rows in table CUST: ' || res);    
END;    
/    
commit;

-------------------------------------------------
--Step 3: do rating 
-------------------------------------------------
DECLARE    
   res number;  
   k_date VARCHAR2(30);   
BEGIN    
   select to_char(sysdate, 'YYYYMMDD HH24:MI:SS') into k_date from dual;
   DBMS_OUTPUT.PUT_LINE('Started doRating: ' || k_date );
   res := doRating ();    
   dbms_output.put_line('Created rows in table EVENT:' || res);    
   select to_char(sysdate, 'YYYYMMDD HH24:MI:SS') into k_date from dual;
   DBMS_OUTPUT.PUT_LINE('Ended doRating: ' || k_date );
END;    
/    
commit;

-------------------------------------------------------
--Step 4: store results to backup table (EVENT_OLD)
-------------------------------------------------------
TRUNCATE TABLE EVENT_OLD ; 
INSERT INTO EVENT_OLD 
  (event_id, customer_id, customer_details, tariff, rate_offer, event_type, event_type_group, call_zone, call_direction, is_int, amount, duration, rounded_duration, volume, rounded_volume, units, unit_rate, charge)
  SELECT  
  event_id, customer_id, customer_details, tariff, rate_offer, event_type, event_type_group, call_zone, call_direction, is_int, amount, duration, rounded_duration, volume, rounded_volume, units, unit_rate, charge
  from EVENT;
commit;

-------------------------------------------------------
--Step 5: update two prices
-------------------------------------------------------
 UPDATE PRICELIST SET data= 170 WHERE name = 'Tarif TA';
 UPDATE PRICELIST SET v_z1_o = 0.45 WHERE name = 'Balicek B3';
 COMMIT;

-------------------------------------------------------
--Step 6 do rating with the updated pricelist table --
-------------------------------------------------------
DECLARE
   res number;
   k_date varchar2(30);    
BEGIN    
   select to_char(sysdate, 'YYYYMMDD HH24:MI:SS') into k_date from dual;
   DBMS_OUTPUT.PUT_LINE('Started doRating: ' || k_date );
   res := doRating();    
   DBMS_OUTPUT.PUT_LINE('Created rows in table EVENT: ' || res);    
   select to_char(sysdate, 'YYYYMMDD HH24:MI:SS') into k_date from dual;
   DBMS_OUTPUT.PUT_LINE('Ended doRating: ' || k_date );
END;    
/    

-------------------------------------------------------
--Step 7: store results to backup table (EVENT_NEW)
-------------------------------------------------------
TRUNCATE TABLE EVENT_NEW ; 
INSERT INTO EVENT_NEW 
  (event_id, customer_id, customer_details, tariff, rate_offer, event_type, event_type_group, call_zone, call_direction, is_int, amount, duration, rounded_duration, volume, rounded_volume, units, unit_rate, charge)
  SELECT  
  event_id, customer_id, customer_details, tariff, rate_offer, event_type, event_type_group, call_zone, call_direction, is_int, amount, duration, rounded_duration, volume, rounded_volume, units, unit_rate, charge
  from EVENT;
commit;

-------------------------------------------------------
--Step 8: insert 3x3 errors and 16 new. 
-------------------------------------------------------
--3x error, two types
update event_new set unit_rate = unit_rate+1, charge= units * (unit_rate+1) where event_id in (2,3,4);
update event_new set call_zone=call_zone+1,  unit_rate = unit_rate+5, charge= units * (unit_rate+5) where event_id in (5,6,7);
update event_new set call_zone=call_zone+2,  unit_rate = unit_rate+7, charge= units * (unit_rate+7) where event_id in (10,11,12);

--16 new - just diff duration, other same
insert into event_new ( event_id , customer_id, customer_details, tariff, rate_offer, event_type, event_type_group, call_zone, call_direction, is_int, amount, duration, rounded_duration, volume, rounded_volume, units, unit_rate, charge )
select event_id + 600000, customer_id, customer_details, tariff, rate_offer, event_type, event_type_group, call_zone, call_direction, is_int, amount, duration+5, rounded_duration, volume, rounded_volume, units, unit_rate, charge
 from event_new where customer_id=2 and event_type_group='voice' and duration in (1,123);
 


