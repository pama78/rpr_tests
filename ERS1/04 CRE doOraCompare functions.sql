----------------------------------------------------------------------------------------------------------
-- Function: doOraCompareInit, doOraCompareRows, doOraCompareDetails
-- Purpose:  compare data in table EVENT_OLD and EVENT_NEW (hardcoded tablenames)
--           result is populated columns cmp_results, cmp_diff and cmp_details
--           cmp_results : Same or Diff or New
--           cmp_diff    : list of columns, where the difference was found
--           cmp_details : list of columns and for each display old and new value 
--           expectations :
--               1) unique key is in the column event_id. it is indexed for faster speeds
--               2) only selected column names are compared - can be tuned by enlarging the variable configuration (in both compare functions)
--                  rate_offer, event_type_group, call_zone, call_direction, is_int, duration, rounded_duration, volume, rounded_volume, units, unit_rate, charge res
--
-- Author:   Pavel Majer
-- Date :    11/11/2021
----------------------------------------------------------------------------------------------------------


CREATE OR REPLACE FUNCTION doOraCompareInit
RETURN VARCHAR2
IS
  cnt INTEGER;
BEGIN
     SELECT COUNT (*) INTO cnt FROM USER_INDEXES WHERE table_name = 'EVENT_NEW' AND index_name = 'EVENT_NEW_IX' ;
     IF (cnt = 0 ) THEN
       EXECUTE IMMEDIATE 'create unique index EVENT_NEW_IX on EVENT_NEW (event_id)';
     END IF;

     SELECT COUNT (*) INTO cnt FROM USER_INDEXES WHERE table_name = 'EVENT_OLD' AND index_name = 'EVENT_OLD_IX' ;
     IF (cnt = 0 ) THEN
       EXECUTE IMMEDIATE 'create unique index EVENT_OLD_IX on EVENT_OLD (event_id)';
     END IF;

     SELECT COUNT (*) INTO cnt FROM USER_TAB_COLUMNS WHERE table_name = 'EVENT_NEW' AND column_name = 'CMP_RESULTS'  ;
     IF (cnt = 0 ) THEN
       EXECUTE IMMEDIATE 'ALTER TABLE EVENT_NEW ADD ( cmp_results varchar2(40), cmp_diff varchar2(400), cmp_details varchar2(4000) )';
     END IF;

     EXECUTE IMMEDIATE 'UPDATE  EVENT_NEW SET cmp_results='''', cmp_diff='''', cmp_details='''' ';
     RETURN ('Columns cmp_results, cmp_diff, cmp_details initialized. Indexes EVENT_NEW_IX, EVENT_OLD_IX exist');
END;
/

CREATE OR REPLACE FUNCTION doOraCompareRows
RETURN VARCHAR2
 IS
  retVal VARCHAR2(400);
BEGIN
  --set all to basic state
    UPDATE EVENT_NEW SET CMP_RESULTS = '', cmp_diff = '', cmp_details='';

  --find those entries, which are exactly the same (on the monitored columns)
    UPDATE EVENT_NEW SET CMP_RESULTS = 'Same' , cmp_diff = 'NA', cmp_details='NA'
    WHERE event_id IN (SELECT new.event_id FROM
   (SELECT event_id, rate_offer||';'|| event_type_group||';'|| call_zone||';'||
              call_direction||';'|| is_int||';'|| duration||';'|| rounded_duration||';'||
              volume||';'|| rounded_volume||';'|| units||';'|| unit_rate||';'|| charge res
              FROM EVENT_OLD) old,
   (SELECT event_id, rate_offer||';'|| event_type_group||';'|| call_zone||';'||
              call_direction||';'|| is_int||';'|| duration||';'|| rounded_duration||';'||
              volume||';'|| rounded_volume||';'|| units||';'|| unit_rate||';'|| charge res
              FROM EVENT_NEW) new
   WHERE old.event_id=new.event_id AND old.res=new.res);

  --find those entries, which are new
  UPDATE EVENT_NEW SET cmp_results = 'New'
       WHERE event_id IN
           (SELECT event_id FROM EVENT_NEW MINUS SELECT event_id FROM EVENT_OLD);

  --remains exist in both and differ, mark them and iterrate over
   UPDATE EVENT_NEW SET CMP_RESULTS = 'Diff' WHERE  CMP_RESULTS IS NULL ;

  --stats
   SELECT LISTAGG(cnt, '; ') WITHIN GROUP (ORDER BY cnt)
   INTO retVal
   FROM (SELECT cmp_results||'='|| COUNT (*) cnt FROM event_new  GROUP BY cmp_results) ;
   RETURN retVal;
END;
/

CREATE OR REPLACE Function doOraCompareDetails
RETURN varchar2
 is 
   TYPE cmp_col_type IS TABLE OF VARCHAR2 (40);
   cmp_cols  cmp_col_type := cmp_col_type ('rate_offer', 'event_type_group',
        'call_zone', 'call_direction', 'is_int', 'duration', 'rounded_duration',
        'volume', 'rounded_volume', 'units', 'unit_rate', 'charge');
   cmp_col VARCHAR2 (40);
   r_new   EVENT_NEW%ROWTYPE;
   val_old VARCHAR2 (40);
   val_new VARCHAR2 (40);
   retVal VARCHAR2(400);
  CURSOR c_new IS SELECT * FROM EVENT_NEW
                  WHERE CMP_RESULTS = 'Diff'  AND cmp_diff IS NULL;
BEGIN
  FOR r_new IN c_new
  LOOP
     FOR i IN 1 .. cmp_cols.COUNT
        LOOP
            cmp_col := cmp_cols (i);
            EXECUTE IMMEDIATE 'select '||cmp_col||' from EVENT_OLD 
                               where event_id = '||r_new.event_id  INTO val_old ;
            EXECUTE IMMEDIATE 'select '||cmp_col|| ' from EVENT_NEW 
                               where event_id = '||r_new.event_id  INTO val_new ;
            IF (val_new != val_old) THEN
              UPDATE EVENT_NEW SET
                    cmp_diff = cmp_diff||cmp_col||';',
                    cmp_details = cmp_details||cmp_col||'('||
                    val_old ||'->'||val_new||');'
              WHERE event_id=r_new.event_id;
            END IF;
          END LOOP;
      END LOOP;
   --stats    
   EXECUTE IMMEDIATE 'SELECT LISTAGG(cnt, ''; '') WITHIN GROUP (ORDER BY cnt)
     FROM ( 
     select ''All diffs=''||count (*) cnt from EVENT_NEW where cmp_results=''Diff''
     union select ''Groups in cmp_diff=''|| count (distinct (cmp_diff)) from event_new where cmp_results=''Diff''
     union select ''Subgroups by cmp_details value=''|| count (distinct (cmp_details)) from event_new where cmp_results=''Diff''   
     )  ' INTO retVal ;
   RETURN retVal;   
END;
/
