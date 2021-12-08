--Count of differences
  SELECT COUNT(*) FROM EVENT_NEW_CLUST WHERE cmp_results='Diff';

--How many groups exist, and how many of them include Diffs? 
select cmp_results, count (distinct (clust)) from EVENT_NEW_CLUST 
group by cmp_results
union
select 'All groups', count (distinct (clust)) from EVENT_NEW_CLUST; 

select count (*) from event_new_clust where event_id in (2210,3950)

select * from event_new_clust where cmp_results = 'New'

desc event_new


select * from event_new where cmp_results='Diff'

select count (*) from event

--Diff	18
--New	14
--Same	97

--Count of differences per group
  SELECT cmp_results, cmp_diff, clust, COUNT (*) FROM EVENT_NEW_CLUST
  WHERE cmp_results = 'Diff'
  GROUP BY  cmp_results, cmp_diff, clust
  ORDER BY clust;
 

 --select for for each group with differences the row closest and most far from the centre
  SELECT event_id,  cmp_diff, cmp_details, clust, round ( clust_dist ) clust_dist
  FROM EVENT_NEW_CLUST WHERE event_id IN
  (
   ( SELECT MIN(event_id)  KEEP (DENSE_RANK FIRST ORDER BY clust, clust_dist)
      FROM EVENT_NEW_CLUST WHERE  cmp_results='Diff'   GROUP BY clust)
    UNION
   ( SELECT MAX(event_id)  KEEP (DENSE_RANK LAST ORDER BY clust, clust_dist) 
      FROM EVENT_NEW_CLUST WHERE  cmp_results='Diff'   GROUP BY clust)
  )
  ORDER BY clust, clust_dist;

-- NEW EST
select * from EVENT_NEW_CLUST where cmp_results='New'

select maX(event_id) from event_new_clust 
where event_id < 600000

select count (*) from event_new_clust

 insert into event_new (event_id , customer_id, customer_details, tariff, rate_offer, event_type, event_type_group, call_zone, call_direction, is_int, amount, duration, rounded_duration, volume, rounded_volume, units, unit_rate, charge )
 select event_id + 300000, customer_id, customer_details, tariff, rate_offer, event_type, event_type_group, call_zone, call_direction, is_int, amount, duration, rounded_duration, volume, rounded_volume, units, unit_rate, charge from event_new where cmp_results= 'Same'
 and event_id < 239000;

 insert into event_old (event_id , customer_id, customer_details, tariff, rate_offer, event_type, event_type_group, call_zone, call_direction, is_int, amount, duration, rounded_duration, volume, rounded_volume, units, unit_rate, charge )
 select event_id + 300000, customer_id, customer_details, tariff, rate_offer, event_type, event_type_group, call_zone, call_direction, is_int, amount, duration, rounded_duration, volume, rounded_volume, units, unit_rate, charge from event_new where cmp_results= 'Same'
 and event_id < 239000;


commit

276

