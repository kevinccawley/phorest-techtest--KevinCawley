SELECT
  `phorest-techtest.source_data.clients`.id,
  first_name,
  last_name,
  email,
  SUM(`phorest-techtest.source_data.services`.loyalty_points) AS services_loyalty,
  SUM(`phorest-techtest.source_data.purchases`.loyalty_points) AS purchases_loyalty,
  SUM(`phorest-techtest.source_data.services`.loyalty_points) + SUM(`phorest-techtest.source_data.purchases`.loyalty_points) AS total_loyalty
FROM `phorest-techtest.source_data.clients`
LEFT JOIN `phorest-techtest.source_data.appointments` ON `phorest-techtest.source_data.clients`.id = `phorest-techtest.source_data.appointments`.client_id
LEFT JOIN `phorest-techtest.source_data.services` ON `phorest-techtest.source_data.appointments`.id = `phorest-techtest.source_data.services`.appointment_id
LEFT JOIN `phorest-techtest.source_data.purchases` ON `phorest-techtest.source_data.appointments`.id = `phorest-techtest.source_data.purchases`.appointment_id
WHERE banned = FALSE
AND start_time >= TIMESTAMP('2018-01-01 00:00:00')
GROUP BY `phorest-techtest.source_data.clients`.id, last_name, first_name, email, `phorest-techtest.source_data.services`.loyalty_points, `phorest-techtest.source_data.purchases`.loyalty_points
ORDER BY total_loyalty
DESC LIMIT 50
