  -- Oriingal slate of questions for part 2
  -- 1. For the calendar year 2020, what were the names of the top 20 committees receiving contributions and how much did they receive?
  -- 2. Who were the top 20 individuals making contributions and how much did they contribute?
  -- 3. How many committees are both recipients and contributors?
  -- 4.Do these results align with your expectations?
  --  Only use contributions with amndt_ind = “N”.

  -- From the FEC
  -- 2015 - present: greater than $200
  -- A contribution will be included if:
  -- The contribution’s election cycle-to-date amount is over $200 for contributions to candidate committees
  -- The contribution’s calendar year-to-date amount is over $200 for contributions to political action committees (PACs) and party committees.




  
  -- Queries to explore various tables' schemas and data types
  -- Question 1
  -- https://stackoverflow.com/questions/45337079/get-big-query-table-schema-from-select-statements
  -- individual contributions
SELECT
  column_name,
  data_type
FROM
  `bigquery-public-data`.fec.INFORMATION_SCHEMA.COLUMNS
WHERE
  table_name = 'indiv20'
ORDER BY
  ordinal_position;
SELECT
  column_name,
  data_type
FROM
  `bigquery-public-data`.fec.INFORMATION_SCHEMA.COLUMNS
WHERE
  table_name = 'indiv20'
ORDER BY
  ordinal_position;


-- Committee information in schema
SELECT
  column_name,
  data_type
FROM
  `bigquery-public-data`.fec.INFORMATION_SCHEMA.COLUMNS
WHERE
  table_name = 'cm20'
ORDER BY
  ordinal_position;
SELECT
  column_name,
  data_type
FROM
  `bigquery-public-data`.fec.INFORMATION_SCHEMA.COLUMNS
WHERE
  table_name = 'cm20'
ORDER BY
  ordinal_position;


  -- Question 2 - "Who were the top 20 individuals making contributions and how much did they contribute?"
  -- this does not account for which committees - yet
  -- Specifies the calendar year 2020 as per the original question regarding committees
  # The transaction types we want are:
  #
  # 15: Contribution
  # 15E: Earmarked Contribution (the target committee is the filer)
  #
  # The transaction types we exclude are:
  #
  # 10: Non-Federal Receipt from Person
  # 11: Tribal Contribution
  # 15C: Contribution from Candidate (I think that means in a self-funded campaign)
  # 19: Electioneering Communication Donation Received (not sure why an individual would do this)
  # 20Y, 21Y, 22Y: Refund: Non-Federal / Tribal / Individual Contribution
  # 24I: Earmarked Intermediary Out (the intermediary is the filer, maybe OTHER_ID has the target?)
  # 24T: Earmarked Intermediary Treasury Out
  -- ZZ is Unknown state - I leave it in the dataset
WITH
  table_top_20 AS (
  SELECT
    amndt_ind,
    name,
    city,
    state,
    zip_code,
    entity_tp,
    transaction_tp,
    employer,
    occupation,
    SUM(transaction_amt) AS total_individual_contributions,
    MIN(transaction_dt) AS min_date,
    MAX(transaction_dt) AS max_date
  FROM
    `bigquery-public-data.fec.indiv20`
  GROUP BY
    name,
    city,
    state,
    zip_code,
    amndt_ind,
    entity_tp,
    transaction_tp,
    employer,
    occupation
  HAVING
    total_individual_contributions > 0
    AND amndt_ind = "N"
    AND entity_tp = 'IND'
    AND transaction_tp IN ('15E',
      '15')
    AND EXTRACT(ISOYEAR
    FROM
      MIN(transaction_dt)) = 2020
    AND EXTRACT(ISOYEAR
    FROM
      MAX(transaction_dt)) = 2020
  ORDER BY
    total_individual_contributions DESC
  LIMIT
    20 )
SELECT
  *
FROM
  table_top_20;



  -- Alternatively we could have constructed this two part query.
  -- Notice here that this is a twist on the original question
  -- Here I return the Top 20 names by state. The level of resolution is reduced
  -- compared to the previous query and here I don't break ties.

with temp_aggregation_table as (
  SELECT
    name,
    state,
    amndt_ind,
    entity_tp,
    transaction_tp,
    SUM(transaction_amt) as total_contributions
    FROM
        `bigquery-public-data.fec.indiv20`
 GROUP BY name,
    state,
    amndt_ind,
    entity_tp,
    transaction_tp     
  HAVING total_contributions > 0
    AND amndt_ind = "N"
    AND entity_tp = 'IND'
    AND transaction_tp IN ('15E',
      '15')
    AND EXTRACT(ISOYEAR
    FROM
      MIN(transaction_dt)) = 2020
    AND EXTRACT(ISOYEAR
    FROM
      MAX(transaction_dt)) = 2020        
 
)
-- 
SELECT
  *
FROM 
  (
    select name, state, total_contributions,
    RANK() OVER (PARTITION BY 
   state
 ORDER BY total_contributions DESC) AS contribution_rank,
    from temp_aggregation_table
  ) AS table_top_20
WHERE
  contribution_rank <= 20 AND state is not NULL
order by state, contribution_rank;


  -- What were the names of the top 20 committees receiving contributions and how much did they receive?
  -- This query reuses the individual contribution logic from above
SELECT
  cmte_nm AS committee_name,
  -- make this more human-readable...difficult for someone to comprehend 
  -- something like 12312321314211412313123123 
  SUM(transaction_amt) / 1000000 AS donations_in_millions
FROM (
  SELECT
    cmte_id,
    transaction_amt,
    CAST(amndt_ind AS STRING),
    entity_tp,
    transaction_tp,
    transaction_dt
  FROM
    `bigquery-public-data.fec.indiv20`
  WHERE
    transaction_amt > 0
    AND amndt_ind IN ("N")
    AND entity_tp = 'IND'
    AND transaction_tp IN ('15E',
      '15')
    AND EXTRACT(ISOYEAR
    FROM
      transaction_dt ) = 2020
    AND EXTRACT(ISOYEAR
    FROM
      transaction_dt) = 2020 ) individual_contributions
INNER JOIN
  `bigquery-public-data.fec.cm20` committee_2020
ON
  committee_2020.cmte_id = individual_contributions.cmte_id
GROUP BY
  committee_name
ORDER BY
  donations_in_millions DESC
LIMIT
  20;

  -- How many committees are both recipients and contributors?
  -- Here I interpret this context that committees give to candidates
  -- and receive contributions from individuals.
  -- I maintain the recipient definition from the other question responses:
  -- that is, individual contributors only in the calendar year 2020
  -- If I broadened the last action to include between committees
  -- we would use this:
  -- https://www.fec.gov/campaign-finance-data/any-transaction-one-committee-another-file-description/
  -- 24K and 24 Z are the specific codes to add to the list of predicates
SELECT
  COUNT (*) AS number_committees_that_give_and_take
FROM (
  SELECT
    DISTINCT *
  FROM (
    SELECT
      *
    FROM (
      SELECT
        cmte_nm AS committee_name
      FROM (
        SELECT
          linkage_id,
          cand_id,
          cmte_id
        FROM
          `bigquery-public-data.fec.ccl20`) link
      INNER JOIN
        `bigquery-public-data.fec.cn20` candidate_table
      ON
        candidate_table.cand_id = link.cand_id
      INNER JOIN
        `bigquery-public-data.fec.cm20` committee_table
      ON
        committee_table.cmte_id = link.cmte_id
      GROUP BY
        committee_table.cmte_nm
        -- I know this is not clean - alias would be better here but I didn't feel like - at least
        -- at the time of this writing - creating another subquery just to surface the committee names
      HAVING
        COUNT(DISTINCT(linkage_id)) > 0
      ORDER BY
        COUNT(DISTINCT(linkage_id)) DESC ) INTERSECT DISTINCT
    SELECT
      DISTINCT *
    FROM (
      SELECT
        cmte_nm AS committee_name
      FROM (
        SELECT
          cmte_id,
          transaction_amt,
          CAST(amndt_ind AS STRING),
          entity_tp,
          transaction_tp,
          transaction_dt
        FROM
          `bigquery-public-data.fec.indiv20`
        WHERE
          transaction_amt > 0
          AND amndt_ind IN ("N")
          AND entity_tp = 'IND'
          AND transaction_tp IN ('15E',
            '15')
          AND EXTRACT(ISOYEAR
          FROM
            transaction_dt ) = 2020
          AND EXTRACT(ISOYEAR
          FROM
            transaction_dt) = 2020 ) individual_contributions
      INNER JOIN
        `bigquery-public-data.fec.cm20` committee_2020
      ON
        committee_2020.cmte_id = individual_contributions.cmte_id
      GROUP BY
        committee_name
        -- I know this is not clean - alias would be better here
        -- I divided by 1 million because the reported figure is not human-
        -- readable. I added an additional predicate here in order to make it
        -- more flexible if there is a need to further reduce the number of 
        -- committees
      HAVING
        SUM(transaction_amt)/ 1000000 > 0 ) ) );


-- this is more nuanced as we can answer which contributors - without identifying the name of the contributor - the most represented -- affiliated companies. This is relevant, for example, we may be interested in Detroit's Big 4 automotive representation
-- due to the controversial election contests that occurred in the 2020 election.
-- This would also enable us to more directly determine the potential wallet share of a company's employees
-- This example query actually teed up the exercise with the 2020 NC state senate seat pitting Tedd Budd and Cal Cunningham.
select city, state, employer,
        ROUND(SUM(transaction_amt) OVER (PARTITION BY city, state, employer),2) employer_state_city,
        ROUND(transaction_amt / SUM(transaction_amt) OVER (PARTITION BY  city, state, employer),2) city_state_employer_share
      from `bigquery-public-data.fec.indiv20` as indiv
      where  transaction_amt > 0
      AND amndt_ind IN ("N")
      AND entity_tp = 'IND'
      AND transaction_tp IN ('15E',
        '15'
      )
  AND EXTRACT(YEAR FROM transaction_dt) = 2020 AND employer IS NOT NULL AND state is not NULL
  AND employer not in ('NOT EMPLOYED', 'RETIRED', 'SELF-EMPLOYED')
  order by employer_state_city, city_state_employer_share DESC;



-- Suppose we have the following scenario:
-- Active voter: a voter is considered active on any day where they have at least one donation
 --in the prior 28 days. For example, if the following records are present in events, the voter
 -- "Bob" is considered active on 2017-04-01 through 2017-04-28 (inclusive) even 
 --if no further activity is detected.
-- Churned voter: a voter is considered to be a churned voter during the 28 days following their 
--last being considered active.
-- A voter is no longer a churned voter if they become active again.

DROP TABLE `seo-project-349214.mydataset.donor_intervals_enriched`; 
CREATE TABLE `seo-project-349214.mydataset.donor_intervals_enriched` AS (
  SELECT name,
    city,
    state,
    zip_code,
    amndt_ind,
    entity_tp,
    transaction_tp,
    employer,
    occupation,
    transaction_amt,
    CAST(transaction_dt AS TIMESTAMP) as timestamped, 
    transaction_dt - MAX(CASE WHEN transaction_amt > 0 THEN transaction_dt END) OVER (
              PARTITION BY 
              name,
              city,
              state,
              zip_code,
              employer,
              occupation
              ORDER BY transaction_dt, 
              transaction_dt ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
              ) AS days_since_last_donation
  FROM `bigquery-public-data.fec.indiv20`
  where  transaction_amt >= 1
      AND amndt_ind IN ("N")
      AND entity_tp = 'IND'
      AND transaction_tp IN ('15E',
        '15'
      )
  AND EXTRACT(YEAR FROM transaction_dt) = 2020 AND employer IS NOT NULL AND state is not NULL
  AND employer not in ('NOT EMPLOYED', 'RETIRED', 'SELF-EMPLOYED')  
  ORDER BY name,
              city,
              state,
              zip_code,
              employer,
              occupation, timestamped DESC
);

--Based on the value from the previous step, we can determine which donors belong to 
--some time interval and which does not occur in any. The condition is as follows: 
--if the amount donated has value at least of one dollar or is no more than 27 days later 
--than the previous donation, then it belongs to the same interval.

--Besides, we will also mark the interval starting donations
--which is going to be useful for the period sequence calculation. 
--We know which donations starts the interval because the value must be more than 
--or equal to 1 donation and the previous qualifying donations must be no more than 27 days ago.
-- here days_since_last_donation is an interval object
DROP Table `seo-project-349214.mydataset.donations_tagged`; 
CREATE TABLE `seo-project-349214.mydataset.donations_tagged` AS (  
      SELECT `seo-project-349214.mydataset.donor_intervals_enriched`.*
      -- does belong to active some interval flag
      ,CASE WHEN (EXTRACT(DAY FROM days_since_last_donation) <= 28)
            AND transaction_amt >= 1 THEN 1
      END AS active_interval
      -- first start of a churned flag
      ,CASE WHEN (EXTRACT(DAY FROM days_since_last_donation)) > 28
            AND transaction_amt < 1 THEN 1         
      END AS churned
      -- churned to active start
      ,CASE WHEN (EXTRACT(DAY FROM days_since_last_donation)) > 28
            AND transaction_amt >= 1 THEN 1         
      END AS start_of_churned_to_active_status  
      FROM `seo-project-349214.mydataset.donor_intervals_enriched`
      ORDER BY name, timestamped  DESC
);
-- now we tag out partitions for every donor
DROP TABLE `seo-project-349214.mydataset.donors_tagged`; 
CREATE TABLE `seo-project-349214.mydataset.donors_tagged` AS (
  SELECT
     `seo-project-349214.mydataset.donations_tagged`.*
        -- 1. Donations: sequence number of the interval calculated as sum of start_of_churned_to_active_status
      ,SUM(start_of_churned_to_active_status) OVER (
         PARTITION BY 
              name,
              city,
              state,
              zip_code,
              employer,
              occupation
              ORDER BY timestamped
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS interval_seq
        -- 2. end of the period computed as qualifying donation criterion plus 27 days
      ,MAX(CASE WHEN transaction_amt >= 1 THEN EXTRACT(DAY FROM timestamped ) + 27 END)
              OVER (
              PARTITION BY 
              name,
              city,
              state,
              zip_code,
              employer,
              occupation
              ORDER BY timestamped
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS interval_end
  FROM  `seo-project-349214.mydataset.donations_tagged`
  --leaving out the out-of-interval donations
  --WHERE active_interval = 1
 ORDER BY name, timestamped  DESC
);
/* 
The last step is to group the donations by the donor and tagged partition (interval_seq field). 
We will extract a start of an interval as the earliest donation date in the interval. 
The end of the interval is calculated as the latest date from the column interval_end. 
The reason is that the cumulative nature of the window functions have not allowed 
us to discover the end of the interval at the first row and we were updating it until the real 
end of the interval. The last column tells us the desired sum of all donations over whole interval before a 
concommitant churn or end of the donors engagement with our organization

This derived end table allows us to create indicator variables based on the number of active intervals
(say they have donated at least 3 times) or only once. Moreover we can now figure out their total days
before they churned. This enables us to ascertain an endpoint for when they drop off  - hence the 
possible use of a time-to-event analysis.  

We can also remove those who donated once and process the more "active" contributors within our campaign.

. */
DROP TABLE `seo-project-349214.mydataset.grouped_final`; 
CREATE TABLE `seo-project-349214.mydataset.grouped_final` AS (
SELECT
      name,
      city,
      state,
      zip_code,
      employer,
      occupation,
      interval_seq
     ,MIN(timestamped) AS interval_start
     ,MAX(interval_end) AS interval_end
     ,SUM(transaction_amt) AS total_transactions
FROM `seo-project-349214.mydataset.donors_tagged`
GROUP BY
      name,
      city,
      state,
      zip_code,
      employer,
      occupation,
      interval_seq
ORDER BY name, interval_start, interval_end DESC
);


