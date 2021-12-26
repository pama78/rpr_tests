--get statistics of input data + Original count of differences
 SELECT COUNT (*) from event_NEW; --  orig
 SELECT COUNT (*) from event_OLD;  --  orig
 SELECT COUNT(*) FROM EVENT_NEW_CLUST WHERE cmp_results='Diff'; --37k diffs
 
--Basic groups -- 3 types
 SELECT cmp_results, COUNT(*) FROM EVENT_NEW_CLUST group by cmp_results;
--Diff	2888
--New	16
--Same	31672

--and count of clusters with having differences within groups -- 26 rows
  SELECT cmp_results, cmp_diff, clust, COUNT (*) FROM EVENT_NEW_CLUST
  WHERE cmp_results = 'Diff'
  GROUP BY  cmp_results, cmp_diff, clust
  ORDER BY clust;  

--CMP_RESULT CMP_DIFF                       CLUST        COUNT(*)
------------ ------------------------------ ---------- ----------
--Diff       rate_offer;unit_rate;          G1_3               96
--Diff       rate_offer;unit_rate;charge;   G1_3              480
--Diff       unit_rate;                     G1_3               96
--Diff       unit_rate;charge;              G1_3              480
--Diff       call_zone;unit_rate;charge;    G2_2                1
--Diff       call_zone;unit_rate;charge;    G2_3                1
--Diff       unit_rate;charge;              G2_3                1
--Diff       call_zone;unit_rate;charge;    G2_4                3
--Diff       unit_rate;charge;              G2_4                1
--Diff       unit_rate;                     G2_5               96
--Diff       unit_rate;charge;              G2_5             1633



--select for for each group with differences the row closest and most far from the centre -- 40 rows
  column clust_dist format 999999999
  column cmp_details format A75
  column cmp_diff format A30
  column clust format A10
  set line 200
  SELECT event_id, cmp_results, cmp_diff, cmp_details, clust, round (clust_dist,2) as clust_dist
  FROM EVENT_NEW_CLUST WHERE event_id IN
  (
   ( SELECT MIN(event_id)  KEEP (DENSE_RANK FIRST ORDER BY clust, clust_dist)
      FROM EVENT_NEW_CLUST WHERE  cmp_results='Diff'   GROUP BY clust)
    UNION
   ( SELECT MAX(event_id)  KEEP (DENSE_RANK FIRST ORDER BY clust, clust_dist)
      FROM EVENT_NEW_CLUST WHERE  cmp_results='Diff'   GROUP BY clust)
  )
  ORDER BY clust, clust_dist;
  
--  EVENT_ID CMP_RESULT CMP_DIFF                       CMP_DETAILS                                                                 CLUST      CLUST_DIST
------------ ---------- ------------------------------ --------------------------------------------------------------------------- ---------- ----------
--     34200 Diff       unit_rate;charge;              unit_rate(200->170);charge(66->56.1);                                       G1_3              900
--        20 Diff       rate_offer;unit_rate;charge;   rate_offer(Balicek B1->Tarif TA);unit_rate(180->170);charge(10.8->10.2);    G1_3              900
--        12 Diff       call_zone;unit_rate;charge;    call_zone(0->2);unit_rate(3.5->10.5);charge(3.43->10.29);                   G2_2              498
--         2 Diff       unit_rate;charge;              unit_rate(3.5->4.5);charge(.07->.09);                                       G2_3              345
--         6 Diff       call_zone;unit_rate;charge;    call_zone(2->3);unit_rate(14->19);charge(.28->.38);                         G2_4              171
--      1263 Diff       unit_rate;                     unit_rate(.5->.45);                                                         G2_5                2
--     30053 Diff       unit_rate;charge;              unit_rate(.5->.45);charge(2.81->2.53);                                      G2_5                2
--7 rows selected.


-- groups, suggested entries for detailed comparison +groups enlarged with cmp_diff grouping
 SELECT event_id, cmp_results, cmp_diff, cmp_details, clust, clust_dist
 from EVENT_NEW_CLUST where event_id in 
 (
 select event_id from
  (
   SELECT event_id, cmp_results, cmp_diff, cmp_details, clust, round (clust_dist,2) as clust_dist
   FROM EVENT_NEW_CLUST WHERE event_id IN
  (
    ( SELECT MIN(event_id)  KEEP (DENSE_RANK FIRST ORDER BY clust, clust_dist)
       FROM EVENT_NEW_CLUST WHERE  cmp_results='Diff'   GROUP BY clust,cmp_diff)
     UNION
    ( SELECT MAX(event_id)  KEEP (DENSE_RANK FIRST ORDER BY clust, clust_dist)
       FROM EVENT_NEW_CLUST WHERE  cmp_results='Diff'   GROUP BY clust,cmp_diff) 
    )
  )
) order by clust, cmp_diff;

--  EVENT_ID CMP_RESULT CMP_DIFF                       CMP_DETAILS                                                                 CLUST      CLUST_DIST
------------ ---------- ------------------------------ --------------------------------------------------------------------------- ---------- ----------
--        70 Diff       rate_offer;unit_rate;          rate_offer(Balicek B1->Tarif TA);unit_rate(180->170);                       G1_3              900
--     16870 Diff       rate_offer;unit_rate;          rate_offer(Balicek B1->Tarif TA);unit_rate(180->170);                       G1_3              900
--     16920 Diff       rate_offer;unit_rate;charge;   rate_offer(Balicek B1->Tarif TA);unit_rate(180->170);charge(59.4->56.1);    G1_3              900
--        20 Diff       rate_offer;unit_rate;charge;   rate_offer(Balicek B1->Tarif TA);unit_rate(180->170);charge(10.8->10.2);    G1_3              900
--     17290 Diff       unit_rate;                     unit_rate(200->170);                                                        G1_3              900
--     34150 Diff       unit_rate;                     unit_rate(200->170);                                                        G1_3              900
--     34200 Diff       unit_rate;charge;              unit_rate(200->170);charge(66->56.1);                                       G1_3              900
--     17300 Diff       unit_rate;charge;              unit_rate(200->170);charge(12->10.2);                                       G1_3              900
--        12 Diff       call_zone;unit_rate;charge;    call_zone(0->2);unit_rate(3.5->10.5);charge(3.43->10.29);                   G2_2              498
--        11 Diff       call_zone;unit_rate;charge;    call_zone(0->2);unit_rate(1.5->8.5);charge(1.47->8.33);                     G2_3              388
--         2 Diff       unit_rate;charge;              unit_rate(3.5->4.5);charge(.07->.09);                                       G2_3              345
--         6 Diff       call_zone;unit_rate;charge;    call_zone(2->3);unit_rate(14->19);charge(.28->.38);                         G2_4              171
--         4 Diff       unit_rate;charge;              unit_rate(4->5);charge(.08->.1);                                            G2_4              598
--      1263 Diff       unit_rate;                     unit_rate(.5->.45);                                                         G2_5                2
--     29883 Diff       unit_rate;                     unit_rate(.5->.45);                                                         G2_5                2
--      1273 Diff       unit_rate;charge;              unit_rate(.5->.45);charge(.49->.44);                                        G2_5                2
--     30053 Diff       unit_rate;charge;              unit_rate(.5->.45);charge(2.81->2.53);                                      G2_5                2




--find how many manual errors are in the selection group
 SELECT event_id, cmp_results, cmp_diff, cmp_details, clust, clust_dist
 from EVENT_NEW_CLUST where event_id in 
 (
  select event_id from
  (
   SELECT event_id, cmp_results, cmp_diff, cmp_details, clust, round (clust_dist,2)
   FROM EVENT_NEW_CLUST WHERE event_id IN
  (
    ( SELECT MIN(event_id)  KEEP (DENSE_RANK FIRST ORDER BY clust, clust_dist)
       FROM EVENT_NEW_CLUST WHERE  cmp_results='Diff'   GROUP BY clust,cmp_diff)
     UNION
    ( SELECT MAX(event_id)  KEEP (DENSE_RANK FIRST ORDER BY clust, clust_dist)
       FROM EVENT_NEW_CLUST WHERE  cmp_results='Diff'   GROUP BY clust,cmp_diff) 
    )
  )
) and event_id in (2,3,4,5,6,7,10,11,12);