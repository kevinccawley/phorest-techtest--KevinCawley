# My Solution

The scenario outlined below can be solved fairly simply by loading *Comb as You Are's* data into a SQL database and writing a query to extract the 50 clients with the most loyalty points.

I used Google BigQuery as my SQL database and loaded the included .csv files manually.
In this scenario, we could use several options for file delivery, such as an SFTP server or a tool like Box.com, ensuring that our customer's data is properly secured during delivery.

Before proceeding, I would also compare row counts from the raw files to the tables created in BigQuery:

clients: 100 rows
appointments: 490 rows
services: 1031 rows
purchases: 476 rows

This ensures no data is lost as we are moving data.

# The SQL Query

The query I wrote is contained in the top_50_loyalty_points.sql file, copied here:

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

The output of this query will provide the client ID, first and last name, email address, loyalty points for services and purchases, and total loyalty points.
This will provide *Comb as You Are* with everything needed to email their top 50 customers.
The limit is set to 70 to determine if there are multiple clients with the same loyalty point total as the 50th client.
This isn't the case, but if it came up we would need to ask our customer if they would like these results included.

The clients table is the main table, joined to the appointments and purchases table.
Banned customers are being excluded and only appointments from 01-01-2018 are being considered.
The results are grouped by client ID to avoid issues with similar names, ordered by total loyalty points, and limited to the top 50 results.

# Testing

To verify that data is exporting correctly using the query, I compared the results to the raw files.
The client with the most loyalty points is client_id: e0779fa6-7635-4df6-b906-d0d665ce5044

The 6 appointments for this client that fall in our timeframe are below.
I manually added the loyalty point totals for these appointments to ensure the query output matches the raw files.

cc6a6059-ceb9-49a7-a12b-9f264f28f029 services 45 purchases 40
a6247fa7-d197-4f2c-be94-08c7d9508048 services 110 purchases 20
463ba6d0-1146-4476-b2f3-45e4d4aaddad services 30 purchases 0
5617ac4d-9dae-4379-87ec-f3050c179065 services 110 purchases 0
18e4f32e-5997-494a-9d1b-dfd5984ab02c services 120 purchases 40
6afa8399-8635-4b6c-9a71-175db7d4f298 services 10 purchases 0
total services 425 purchases 100

At this point, the loyalty point totals do not match between the query and the raw files. The query has 470 points in services and 260 in purchases.

It's a good thing we tested! The next step is to ensure that the date where clause is functioning properly by adding the other two appointments that occurred before 2018:

e3f6cfd4-b70b-47fb-86f3-5280dfc8abfe services 20 purchases 35
5f187767-8b2d-4e17-9dab-08b2b5e99b9e services 100 purchases 30

These totals also don't add up (545 and 165 including the pre-2018 appointments compared to 470 and 260), so something else is going on with the query that we'll need to address.

# Problem Description

*Comb as You Are* have decided to ditch their old salon software provider
and upgrade to *Phorest* to avail of its best in class client retention tools.
They're exicted to finally offer their clients the opportunity to book online.

They've exported their clients appointment data from their old provider and
would like to email their top 50 most loyal clients of the past year with the news
that they can now book their next appointment online.

# Problem Spec

The exported data is split across 4 files.

* clients.csv
* appointments.csv
* services.csv
* purchases.csv

Each client has many appointments and are related through a `client_id` property on the appointment
Each appointment has many services and are related through an `appointment_id` property on the service
Each appointments has 0 or many purchases and are related through an `appointment_id` property on the purchase
Services and purchases have an associated number of loyalty points defined as a property
Clients have a boolean banned property defined on the client

# Solution

We would expect a simple web application that would expose few REST api endpoints: 
* an endpoint to consume and parse csv files and import data into some database
* an endpoint to list the top X number (endpoint parameter eg: 50) of clients that have accumulated the most loyalty points since Y date (endpoint parameter eg: 2018-01-01). Please exclude any banned clients.

Nice to have: 
* at least one endpoint to update one of the entities
* an endpoint to fetch a single entity by id
* an endpoint to delete one of the entities

Endpoints should be designed with RESTful best practices. Request/response bodies should be in json format. Remember about the validation. 

Do as much as you can in the time you have available to you. Please still submit your solution even if it's not complete. You can always add a few notes stating what's missing and/or how you would improve the solution if you had more time. 

## Testing
We would prefer to see a partial solution which is accompanied by tests, than a fully working solution without tests.

# Submission  

Please submit your solution in the form of a link to a public source control repository which contains your code e.g Github, Gitlab etc. Ideally we would like to see the development progress by viewing commits history. 
