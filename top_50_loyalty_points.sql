SELECT 
    c.id, 
    c.email,
    c.first_name,
    c.last_name,
    COALESCE(s.services_loyalty_points, 0) AS services_loyalty_points,
    COALESCE(p.purchases_loyalty_points, 0) AS purchases_loyalty_points,
    COALESCE(s.services_loyalty_points, 0) + COALESCE(p.purchases_loyalty_points, 0) AS total_loyalty_points
FROM 
    `phorest-techtest.source_data.clients` c
LEFT JOIN (
    SELECT 
        a.client_id,
        SUM(s.loyalty_points) AS services_loyalty_points
    FROM 
        `phorest-techtest.source_data.appointments` a
    JOIN 
        `phorest-techtest.source_data.services` s 
        ON a.id = s.appointment_id
    WHERE 
        a.start_time >= TIMESTAMP('2018-01-01 00:00:00')
    GROUP BY 
        a.client_id
) s ON c.id = s.client_id
LEFT JOIN (
    SELECT 
        a.client_id,
        SUM(p.loyalty_points) AS purchases_loyalty_points
    FROM 
        `phorest-techtest.source_data.appointments` a
    LEFT JOIN 
        `phorest-techtest.source_data.purchases` p 
        ON a.id = p.appointment_id
    WHERE 
        a.start_time >= TIMESTAMP('2018-01-01 00:00:00')
    GROUP BY 
        a.client_id
) p ON c.id = p.client_id
WHERE 
    c.banned = FALSE
ORDER BY 
    total_loyalty_points DESC
LIMIT 50;
