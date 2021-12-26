----------------------------------------------------------------------------------------------------------
-- Script:   DML insert queries for basic system tables 
-- Purpose:  create tables
--           PRICELIST - for definition of tariffs, addons...
--           CUST 
--           EVENT     : for holding the rated events
--
-- Author:   Pavel Majer
-- Date :    11/11/2021
----------------------------------------------------------------------------------------------------------


-----------------------------------
--Pricelist table creation
-----------------------------------
SET DEFINE OFF;
CREATE TABLE PRICELIST
(
  ID           NUMBER,
  NAME         VARCHAR2(40 BYTE),
  TYPE         VARCHAR2(1 BYTE),
  V_ONN        NUMBER,
  V_OFN        NUMBER,
  V_Z1_O       NUMBER,
  V_Z1_I       NUMBER,
  V_Z2_O       NUMBER,
  V_Z2_I       NUMBER,
  V_Z3_O       NUMBER,
  V_Z3_I       NUMBER,
  SMS          NUMBER,
  DATA         NUMBER,
  TAR_DUR_MIN  NUMBER,
  TAR_DUR_RND  NUMBER
) ;

-----------------------------------
--Customer table creation
-----------------------------------
CREATE TABLE CUST
(
  CUST      NUMBER,
  TARIFF    VARCHAR2(40 BYTE),
  ROUNDING  VARCHAR2(40 BYTE),
  ADDONS    VARCHAR2(4000 BYTE)
);

-----------------------------------
--Event table creation
-----------------------------------
CREATE TABLE EVENT
(
  EVENT_ID          NUMBER,
  CUSTOMER_ID       NUMBER,
  CUSTOMER_DETAILS  VARCHAR2(400 BYTE),
  TARIFF            VARCHAR2(40 BYTE),
  RATE_OFFER        VARCHAR2(40 BYTE),
  EVENT_TYPE        VARCHAR2(10 BYTE),
  EVENT_TYPE_GROUP  VARCHAR2(10 BYTE),
  CALL_ZONE         VARCHAR2(1 BYTE),
  CALL_DIRECTION    VARCHAR2(1 BYTE),
  IS_INT            VARCHAR2(1 BYTE),
  AMOUNT            NUMBER,
  DURATION          NUMBER,
  ROUNDED_DURATION  NUMBER,
  VOLUME            NUMBER,
  ROUNDED_VOLUME    NUMBER,
  UNITS             NUMBER,
  UNIT_RATE         NUMBER,
  CHARGE            NUMBER
);

-----------------------------------
--Tables for Event comparison (needed to exist, so the plsql functions could be build)
-----------------------------------
CREATE TABLE EVENT_NEW as select * from EVENT;
CREATE TABLE EVENT_OLD as select * from EVENT;
CREATE TABLE EVENT_NEW_CLUST as select * from EVENT; 
ALTER TABLE EVENT_NEW ADD ( cmp_results varchar2(40), cmp_diff varchar2(400), cmp_details varchar2(4000) );
ALTER TABLE EVENT_OLD ADD ( cmp_results varchar2(40), cmp_diff varchar2(400), cmp_details varchar2(4000) );

CREATE UNIQUE INDEX EVENT_NEW_IX on EVENT_NEW (event_id); 
CREATE UNIQUE INDEX EVENT_OLD_IX on EVENT_OLD (event_id); 