----------------------------------------------------------------------------------------------------------
-- Function: createCustByPricelist
-- Purpose:  for every unique combination of tariff, tariffication and 0..n addons create one customer
--           for 3 tariffs, 3 addons and 3 tariffications will have 72 customers 3*3*2^3
--           results are stored to table CUST
-- Author:   Pavel Majer
-- Date :    11/11/2021
----------------------------------------------------------------------------------------------------------
 
CREATE OR REPLACE FUNCTION createCustByPricelist
RETURN NUMBER
 IS
   tbl_exist  INTEGER;
    cnumber    INTEGER;   -- count of results
    query VARCHAR2(4000);
BEGIN
  SELECT COUNT(*) INTO tbl_exist FROM user_tables WHERE table_name = 'CUST';
  IF tbl_exist = 1 THEN
    EXECUTE IMMEDIATE 'drop table CUST';
  END IF;
  EXECUTE IMMEDIATE 'CREATE TABLE CUST 
   AS
    SELECT ROWNUM     AS cust,
           tariff,
           rounding,
           addons
      FROM (SELECT name     AS tariff
              FROM PRICELIST
             WHERE TYPE = ''T''),
           (SELECT name     AS rounding
              FROM PRICELIST
             WHERE TYPE = ''R''),
           ((    SELECT SYS_CONNECT_BY_PATH (name, '';'') AS addons
                   FROM PRICELIST
                  WHERE TYPE = ''A''
             CONNECT BY NOCYCLE name > PRIOR name)
            UNION
            SELECT NULL FROM DUAL)
      ';
  SELECT COUNT (*) INTO cnumber FROM CUST;
  RETURN cnumber;
END;
/