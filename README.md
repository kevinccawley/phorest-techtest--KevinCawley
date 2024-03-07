# Introduction

First off, I'd like to apologize for not having this to you sooner. This week became busier than anticipated due to unexpected appointments combined with prior commitments.
Next, as you may be able to tell, I am not a regular github user. I apologize if my commit history is hard to follow. I did include as much of my thought process in this document as possible.

Finally, I'd be happy to walk through anything included below on a Google Meet or Zoom call if more information is necessary.

Thank you for your time and for providing a challenge!

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

We'll move to the next client in the query results to see if we can narrow down what's happening:

1c202302-5ecb-4675-9737-c4e0ce4b996f services 475 purchases 210 total 685

This client has 3 appointments in our timeframe:

1c202302-5ecb-4675-9737-c4e0ce4b996f services 130 purchases 15
f54fa9af-1922-4074-8247-8d5fc5b07fb6 services 130 purchases 55
0f318771-612c-419f-a1ee-88553d5f336c services 85 purchases 0

Again, we're not adding up. Taking another look at the query, it may be because some of the fields from the clients table are included in the group by clause.
We may need to nest the query in order for data to calculate accurately, then combine with the clients table.

# Brief Interlude

It's the next morning, and I'll be working on this as other commitments allow.
My plans for today include:

1. Breaking the SQL query apart and rebuilding piece by piece
2. Looking into automating the workflow using an ETL tool like n8n

I'll be looking into my access to ETL tools I've used in previous positions to see if I'm able to put together a workflow.

# Update

I can access n8n, so will be putting together a sample workflow for automating the process of picking up the data and querying it.

# Automation Update

I created the sample n8n workflow and exported it as a JSON file (phorest_techtest_n8n_workflow.json).
I also took a screenshot of the workflow for a visual representation (phorest_techtest_n8n_workflow_screenshot.png).

My free trial doesn't include the ability to insert data into BigQuery, so the automation piece isn't fully functioning.
However, the proof of concept should be visible and I've used similar workflows in previous positions.

The Schedule Trigger node can be used to run the workflow on a schedule of our choosing. It's currently set to run daily at midnight.
This node can be removed if we have a one-time data transfer. I included it to show that we can grab current data from customers during a migration project to ensure we have up to date information.

I chose Box to store the files, but this node can be updated based on how we expect to receive data from *Comb as You Are*. We can connect to an SFTP server or many other services through n8n.

The first BigQuery node is creating or replacing the 4 tables (appointments, clients, purchases, and services).
From here, we insert the data from the fresh files into these tables. We can run 4 nodes together, as shown, or write a SQL query to combine the insert of all 4 tables into one node.

Once fresh data has been inserted, we can run our query to find the 50 customers with the most loyalty points.

The results can be shared in a number of ways. I opted to convert them into an Excel file and email the file to our customer through Outlook.
Other options could be to load the file back into Box.com for customer retrieval, send to a CRM like HubSpot or Salesforce, or export directly into a marketing tool like MailChimp.

With the automation piece demonstrated, I'm returning to the SQL query in an attempt to get data to total accurately.

# SQL Query Revisited

Again, it's the next day, and I'm returning to the SQL query. I'm beginning by breaking the query into sections to determine where the calculation error is occurring.

I can get accurate totals when summing loyalty points on services and products on their own, using queries like:

SELECT
  appointment_id,
  SUM(IFNULL(loyalty_points,0)) AS services_loyalty
FROM `phorest-techtest.source_data.services`
GROUP BY appointment_id
ORDER BY services_loyalty
DESC LIMIT 70

and:

SELECT
  appointment_id,
  SUM(IFNULL(loyalty_points,0)) AS purchases_loyalty
FROM `phorest-techtest.source_data.purchases`
GROUP BY appointment_id
ORDER BY purchases_loyalty
DESC LIMIT 70

But when these are combined, totals again are off, using a query like:

SELECT
  `phorest-techtest.source_data.services`.appointment_id,
  SUM(IFNULL(`phorest-techtest.source_data.services`.loyalty_points,0)) AS services_loyalty,
  SUM(IFNULL(`phorest-techtest.source_data.purchases`.loyalty_points,0)) AS purchases_loyalty,
  SUM(IFNULL(`phorest-techtest.source_data.services`.loyalty_points,0) + IFNULL(`phorest-techtest.source_data.purchases`.loyalty_points,0)) AS total_loyalty
FROM `phorest-techtest.source_data.services`
LEFT JOIN `phorest-techtest.source_data.purchases` ON `phorest-techtest.source_data.services`.appointment_id = `phorest-techtest.source_data.purchases`.appointment_id
GROUP BY appointment_id
ORDER BY total_loyalty
DESC LIMIT 70

In order to solve this issue, we'll break the components down using WITH statements. The first attempt at the query looks like this:

WITH services AS 
  (SELECT
  appointment_id,
  SUM(IFNULL(loyalty_points,0)) AS services_loyalty
  FROM `phorest-techtest.source_data.services`
  GROUP BY appointment_id
  ORDER BY services_loyalty),
  purchases AS
  (SELECT
  appointment_id,
  SUM(IFNULL(loyalty_points,0)) AS purchases_loyalty
  FROM `phorest-techtest.source_data.purchases`
  GROUP BY appointment_id
  ORDER BY purchases_loyalty)
SELECT
  client_id,
  first_name,
  last_name,
  email,
  services.services_loyalty,
  purchases.purchases_loyalty,
  (services.services_loyalty + purchases.purchases_loyalty) AS total_loyalty
FROM
  `phorest-techtest.source_data.appointments`
LEFT JOIN `phorest-techtest.source_data.clients` ON `phorest-techtest.source_data.appointments`.client_id = `phorest-techtest.source_data.clients`.id
LEFT JOIN services ON `phorest-techtest.source_data.appointments`.id = services.appointment_id
LEFT JOIN purchases ON `phorest-techtest.source_data.appointments`.id = purchases.appointment_id
WHERE banned = FALSE
AND start_time >= TIMESTAMP('2018-01-01 00:00:00')
GROUP BY client_id, last_name, first_name, email, services.services_loyalty, purchases.purchases_loyalty
ORDER BY total_loyalty
DESC LIMIT 70

Our top client using this query has client_id:

5874a4fc-d96c-426f-8ae8-c7dfa5b60c3e

with 200 services loyalty and 55 purchases loyalty. To verify, we'll return to the raw data, where we see 3 appointments that fall in our timeframe:

81d17e64-b797-431d-a81c-88da3956d05f services 200 purchases 55
4cda1739-fc09-498d-a665-5abc83d5dc9f services 20 purchases 0
778ea773-5c57-43c4-873a-226934b1f0a3 services 70 purchases 10

The totals from the first appointment match, but the other appointments are not being factored in.

We need to figure out a better way to phrase the query so the joins don't interfere with the aggregate functions (SUM).

# Next SQL Query Iteration

Moving the point totals into the from statement instead of using a WITH statement to see if this helps with inaccurate calculations, and using COALESCE instead of IFNULL:

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
LIMIT 70;

We have the same top customer as previous iterations:

e0779fa6-7635-4df6-b906-d0d665ce5044 services 425 purchases 100 total 525

And we again verify using the source data, finding these appointments in our timeframe:

cc6a6059-ceb9-49a7-a12b-9f264f28f029 services 45 purchases 40
a6247fa7-d197-4f2c-be94-08c7d9508048 services 110 purchases 20
463ba6d0-1146-4476-b2f3-45e4d4aaddad services 30 purchases 0
5617ac4d-9dae-4379-87ec-f3050c179065 services 110 purchases 0
18e4f32e-5997-494a-9d1b-dfd5984ab02c services 120 purchases 40
6afa8399-8635-4b6c-9a71-175db7d4f298 services 10 purchases 0
total: services 425 purchases 100

Success!

# Further Testing

With more time and fully-functioning tooling, we would test the ETL workflow and tweak as necessary.
I'd also manually compare point totals for more clients to ensure the query works in all situations.

The clients with the 48th, 49th, and 50th highest loyalty point totals all have 125 points. The client in 51st place has 120 points, so we won't need to address a tie.
The final version of the SQL query (contained in the top_50_loyalty_points.sql file) replaces the limit of 70 with a limit of 50 because of this.

Before loading this data into *Phorest*, we may also want to look at data formatting. The email addresses appear okay, but the phone numbers have a variety of formats.
We can use regular expressions to ensure we're loading data in the same format for phone numbers and that email addresses are valid:

REGEXP_REPLACE(phone_number, '[^0-9]', '')
REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')

# Original Problem Below #

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
