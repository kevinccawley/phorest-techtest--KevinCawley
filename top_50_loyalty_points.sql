SELECT
  client_id,
  first_name,
  last_name,
  email,
  SUM(IFNULL(`phorest-techtest.source_data.services`.loyalty_points,0)) AS services_loyalty,
  SUM(IFNULL(`phorest-techtest.source_data.purchases`.loyalty_points,0)) AS purchases_loyalty,
  SUM(IFNULL(`phorest-techtest.source_data.services`.loyalty_points,0)) + SUM(IFNULL(`phorest-techtest.source_data.purchases`.loyalty_points,0)) AS total_loyalty
FROM `phorest-techtest.source_data.clients`
LEFT JOIN `phorest-techtest.source_data.appointments` ON `phorest-techtest.source_data.appointments`.client_id = `phorest-techtest.source_data.clients`.id
LEFT JOIN `phorest-techtest.source_data.services` ON `phorest-techtest.source_data.appointments`.id = `phorest-techtest.source_data.services`.appointment_id
LEFT JOIN `phorest-techtest.source_data.purchases` ON `phorest-techtest.source_data.appointments`.id = `phorest-techtest.source_data.purchases`.appointment_id
WHERE banned = FALSE
AND start_time >= TIMESTAMP('2018-01-01 00:00:00')
GROUP BY client_id, last_name, first_name, email
ORDER BY total_loyalty
DESC LIMIT 70
