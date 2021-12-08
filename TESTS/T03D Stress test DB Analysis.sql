--Original count of differences
  SELECT COUNT(*) FROM EVENT_NEW_CLUST WHERE cmp_results='Diff'; --9k diffs
 
--#Basic groups and representatives -- 14 groups
  SELECT cmp_results, cmp_diff, clust, COUNT (*) FROM EVENT_NEW_CLUST
  WHERE cmp_results = 'Diff'
  GROUP BY  cmp_results, cmp_diff, clust
  ORDER BY clust;
 
 --select for for each group with differences the row closest and most far from the centre
  SELECT event_id, cmp_results, cmp_diff, cmp_details, clust, round (clust_dist,2)
  FROM EVENT_NEW_CLUST WHERE event_id IN
  (
   ( SELECT MIN(event_id)  KEEP (DENSE_RANK FIRST ORDER BY clust, clust_dist)
      FROM EVENT_NEW_CLUST WHERE  cmp_results='Diff'   GROUP BY clust)
    UNION
   ( SELECT MAX(event_id)  KEEP (DENSE_RANK FIRST ORDER BY clust, clust_dist)
      FROM EVENT_NEW_CLUST WHERE  cmp_results='Diff'   GROUP BY clust)
  )
  ORDER BY clust, clust_dist;

