--Original count of differences
  SELECT COUNT(*) FROM EVENT_NEW_CLUST WHERE cmp_results='Diff';
 
--#Basic groups and representatives
  SELECT cmp_results, cmp_diff, clust, COUNT (*) FROM EVENT_NEW_CLUST
  WHERE cmp_results = 'Diff'
  GROUP BY  cmp_results, cmp_diff, clust
  ORDER BY clust;
 
 --select for for each group with differences the row closest and most far from the centre
  SELECT event_id, cmp_results, cmp_diff, cmp_details, clust, clust_dist
  FROM EVENT_NEW_CLUST WHERE event_id IN
  (
   ( SELECT MIN(event_id)  KEEP (DENSE_RANK FIRST ORDER BY clust, clust_dist)
      FROM EVENT_NEW_CLUST WHERE  cmp_results='Diff'   GROUP BY clust)
    UNION
   ( SELECT MAX(event_id)  KEEP (DENSE_RANK LAST ORDER BY clust, clust_dist)
      FROM EVENT_NEW_CLUST WHERE  cmp_results='Diff'   GROUP BY clust)
  )
  ORDER BY clust, clust_dist;
  
--Selected data samples - 2 representatives from each group (extremes)
--1790	Diff	rate_offer;unit_rate;charge;	rate_offer(Balicek B1->Tarif TA);unit_rate(180->170);charge(21.6->20.4);	G1_11	0
--50	Diff	rate_offer;unit_rate;charge;	rate_offer(Balicek B1->Tarif TA);unit_rate(180->170);charge(21.6->20.4);	G1_11	0
--3950	Diff	unit_rate;charge;	unit_rate(200->170);charge(24->20.4);	G1_12	0
--2210	Diff	unit_rate;charge;	unit_rate(200->170);charge(24->20.4);	G1_12	0
--30	Diff	rate_offer;unit_rate;charge;	rate_offer(Balicek B1->Tarif TA);unit_rate(180->170);charge(10.8->10.2);	G1_20	1.33333333333332
--1780	Diff	rate_offer;unit_rate;charge;	rate_offer(Balicek B1->Tarif TA);unit_rate(180->170);charge(10.8->10.2);	G1_20	16.3333333333334
--2180	Diff	unit_rate;charge;	unit_rate(200->170);charge(12->10.2);	G1_4	1495.166976
--3910	Diff	unit_rate;	unit_rate(200->170);	G1_4	52751.0033716789
--60	Diff	rate_offer;unit_rate;charge;	rate_offer(Balicek B1->Tarif TA);unit_rate(180->170);charge(59.4->56.1);	G1_9	74300.9515135183
--3960	Diff	unit_rate;charge;	unit_rate(200->170);charge(66->56.1);	G1_9	74300.9515135183
--1133	Diff	unit_rate;charge;	unit_rate(.5->.45);charge(2.81->2.53);	G2_29	58.7970333333336
--3713	Diff	unit_rate;charge;	unit_rate(.5->.45);charge(3->2.7);	G2_29	31057.4872269429
--1103	Diff	unit_rate;charge;	unit_rate(.5->.45);charge(.5->.45);	G2_39	285.214108444444
--3603	Diff	unit_rate;	unit_rate(.5->.45);	G2_39	59229.0758421921
