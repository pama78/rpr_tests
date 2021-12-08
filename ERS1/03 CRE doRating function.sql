----------------------------------------------------------------------------------------------------------
-- Function: doRating 
-- Purpose:  For every customer in the table CUST create and rate the set of events
--           events should be for cartesian combination of event types and amounts/duration - configurable
--           results are stored to table EVENT
-- Author:   Pavel Majer
-- Date :    11/11/2021
----------------------------------------------------------------------------------------------------------

CREATE OR REPLACE Function doRating 
RETURN number
 is 
--Rating FLOW in PL/SQL :
    /*confiugrations
    || for every customer will be created one event with amount (duration/size/count) 
    || and type/destination defined in event_types
    */
    TYPE nt_type IS TABLE OF NUMBER;
    amounts  nt_type := nt_type (1, 59, 60, 63, 123, 337);  --durations
    TYPE et_type IS TABLE OF VARCHAR2 (10);             --event types
    event_types  et_type := et_type ('v_onn', 'v_ofn', 'v_z1_o', 'v_z1_i', 'v_z2_o', 'v_z2_i', 'v_z3_o', 'v_z3_i', 'sms', 'data');
    /* technical variables are below */
    event_id         INTEGER := 0;  --- unique identifier of events (for comparison)
    event_type       VARCHAR2 (10); -- temporary variable for iteration
    event_type_group VARCHAR2 (10); -- temporary variable for iteration
    rate_offer       VARCHAR2 (30); -- temporary variable for iteration
    call_zone        VARCHAR2 (1);  -- f.e. event v_z2_o - will be 2, for onn/offn=0
    call_direction   VARCHAR2 (1);  -- f.e. event v_z1_o - will be O, for onn/ofn=o
    is_int           VARCHAR2 (1);  -- if voice call is to different zone = Y
    rate             FLOAT;           -- lowest retrieved rate from pricelist/addons
    amount           INTEGER;   -- input amount, either volume or duration
    volume           INTEGER;   -- amount (occurences/Kbytes) in event
    rounded_volume   INTEGER;   -- rounded_volume for SMS/Data (for future use)
    duration         INTEGER;   -- original duration for voice calls
    rounded_duration INTEGER;   -- amount (duration) after minimal duration and rounding
    divider          INTEGER;   -- duration events per 60s, data 1024kb, SMS for 1 piece)
    units            FLOAT;     -- units used by event - 60s=1 minute, 1 SMS = 1, 1024B=1Kb
    charge           FLOAT;      -- for storing final event charge
    query            VARCHAR2 (4000); -- storing dynamically generated queries
    cnumber          INTEGER;   -- count of results
    CURSOR C_CUST IS SELECT cust, tariff, rounding, addons FROM CUST ORDER BY cust;
BEGIN
    EXECUTE IMMEDIATE 'truncate table EVENT';
    FOR r_cust IN C_CUST
    LOOP
        FOR i IN 1 .. amounts.COUNT
        LOOP
            amount := amounts (i);
            FOR j IN 1 .. event_types.COUNT
            LOOP
                event_type := event_types (j);
                event_id := event_id + 1;
                volume:=NULL;
                rounded_volume:=NULL;
                duration:=NULL;
                rounded_duration:=NULL;
                call_zone:=NULL;
                call_direction:=NULL;

             /* Step 1: get basic rate and addon rates-get the lowest and store to rate  */
                query :=  'select * from (select name, ' || event_type || ' from PRICELIST 
                           where name in ('''|| r_cust.tariff || ''',''' ||
                           (REPLACE (SUBSTR (r_cust.addons, 2), ';', ''',''')) || ''') 
                            and '|| event_type || ' is not null 
                           order by '|| event_type ||' ) where rownum =1';
                EXECUTE IMMEDIATE query  INTO rate_offer, rate;

             /* Step 2 : set event group voice/sms/data  
                  || get the zone for international calls, or 0 for national
                  || store the voice duration to column duration
                  || store the SMS/data amount to volume and rounded_volume */
                IF ( SUBSTR (event_type, 1,1) = 'v' )
                     THEN
                        event_type_group:='voice';
                        duration:=amount;
                        IF (REGEXP_LIKE (event_type, '^v_z[[1-9]_[o|i]' ))
                           THEN
                                call_zone:=SUBSTR(event_type, 4,1); --zone 1,2,3
                                call_direction:=UPPER( SUBSTR(event_type, 6,1)) ; -- O / I
                                is_int:='Y';
                           ELSE
                                call_direction:='O'; --outgoing
                                call_zone:='0'; --znoe 0
                                is_int:='Y';
                        END IF;
                     ELSE
                         event_type_group:=event_type;
                         volume:=amount;
                END IF;

                /* Step 3 : convert the units – voice/60, data/1024*/
                SELECT CASE
                           WHEN event_type_group = 'data'  THEN 1024
                           WHEN event_type_group = 'sms'   THEN 1
                           WHEN event_type_group = 'voice' THEN 60
                       END
                  INTO divider   FROM DUAL;

                /* Step 4: apply minimal duration and rounding on duration based events 
                ||calculate used units and final charge */
                IF ( event_type_group = 'voice' )
                THEN
                  SELECT GREATEST (tar_dur_min, amount)
                    INTO rounded_duration FROM PRICELIST  WHERE name = r_cust.rounding;
                  SELECT CASE
                    WHEN (MOD (rounded_duration, tar_dur_rnd) = 0)
                    THEN ( TRUNC (rounded_duration/tar_dur_rnd))* tar_dur_rnd
                    WHEN (MOD (rounded_duration, tar_dur_rnd) != 0)
                    THEN ( TRUNC (rounded_duration/tar_dur_rnd))* tar_dur_rnd + tar_dur_rnd
                  END
                  INTO rounded_duration
                  FROM PRICELIST  WHERE name = r_cust.rounding;
                  units:=ROUND ((rounded_duration / divider), 2);
                  charge:=ROUND (units * rate, 2);
                ELSE
                 rounded_volume:=amount;
                 units:=ROUND ((rounded_volume / divider), 2);
                 charge:= ROUND(units * rate, 2 );
                END IF;

                /* Step 5 : store rating results to table EVENT */
                INSERT INTO EVENT
                 (event_id, customer_id, customer_details, tariff, rate_offer, event_type,
                  event_type_group, call_direction, call_zone, is_int, amount, volume,
                  rounded_volume, duration, rounded_duration, unit_rate, units , charge )
                VALUES ( event_id, r_cust.cust, '#T:' || r_cust.tariff ||' #R:'||
                  r_cust.rounding || ' #A:' || r_cust.addons, r_cust.tariff, rate_offer,
                  event_type, event_type_group, call_direction, call_zone, is_int, amount,
                  volume, rounded_volume, duration, rounded_duration, rate, units, charge);

            END LOOP;
        END LOOP;
    END LOOP;
 
  SELECT count (*) into cnumber from event; 
  return cnumber;
END;
/