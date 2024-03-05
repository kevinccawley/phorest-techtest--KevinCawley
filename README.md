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

The output of this query will provide the client ID, first and last name, email address, loyalty points for services and purchases, and total loyalty points.
This will provide *Comb as You Are* with everything needed to email their top 50 customers.

The clients table is the main table, joined to the appointments and purchases table.
Banned customers are being excluded and only appointments from 01-01-2018 are being considered.
The results are grouped by client ID to avoid issues with similar names, ordered by total loyalty points, and limited to the top 50 results.

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
