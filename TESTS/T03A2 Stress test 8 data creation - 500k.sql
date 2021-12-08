 insert into event_new (event_id , customer_id, customer_details, tariff, rate_offer, event_type, event_type_group, call_zone, call_direction, is_int, amount, duration, rounded_duration, volume, rounded_volume, units, unit_rate, charge )
 select event_id + 300000, customer_id, customer_details, tariff, rate_offer, event_type, event_type_group, call_zone, call_direction, is_int, amount, duration, rounded_duration, volume, rounded_volume, units, unit_rate, charge from event_new where cmp_results= 'Same'
 and event_id < 239000;

 insert into event_old (event_id , customer_id, customer_details, tariff, rate_offer, event_type, event_type_group, call_zone, call_direction, is_int, amount, duration, rounded_duration, volume, rounded_volume, units, unit_rate, charge )
 select event_id + 300000, customer_id, customer_details, tariff, rate_offer, event_type, event_type_group, call_zone, call_direction, is_int, amount, duration, rounded_duration, volume, rounded_volume, units, unit_rate, charge from event_new where cmp_results= 'Same'
 and event_id < 239000;
