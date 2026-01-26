# CEU Modern Data Platforms

Data Engineering 2 - Modern Data Platforms: dbt, Snowflake, Databricks, Apache Spark

---

## Installation

1. **Databricks:** Sign up for Databricks Free Edition: https://www.databricks.com/learn/free-edition
2. **Snowflake:** Register to Snowflake: https://signup.snowflake.com/?trial=student&cloud=aws&region=us-west-2
3. **Snowflake:** Set up Snowflake tables: https://dbtsetup.nordquant.com/?course=ceu
4. **dbt:** Fork this repo as a private repository and clone it to your PC
5. **dbt:** Ensure you have a compatible Python Version: https://docs.getdbt.com/faqs/Core/install-python-compatibility (if you don't, install Python 3.13)
6. **dbt:** Install uv: https://docs.astral.sh/uv/getting-started/installation/
7. **dbt:** Install packages: `uv sync`
8. **dbt:** Activate the virtualenv:
   - Windows (PowerShell): `.\.venv\Scripts\Activate.ps1`
   - Windows (CMD): `.venv\Scripts\activate.bat`
   - WSL (Windows Subsystem for Linux): `source .venv/bin/activate`
   - macOS / Linux: `source .venv/bin/activate`

---

## Starting a dbt Project

Create a dbt project (all platforms):
```sh
dbt init --skip-profile-setup airbnb
```

Once done, drag and drop the `profiles.yml` file you downloaded to the `airbnb` folder.

Test if dbt works:
```sh
dbt debug
```

### Clean Up Example Files

From within the `airbnb` folder, remove the example models that dbt created by default:
```sh
rm -rf models/example
```

Also remove the example model configuration from `dbt_project.yml`. Delete these lines at the end of the file:
```yaml
models:
  airbnb:
    # Config indicated by + and applies to all files under models/example/
    example:
      +materialized: view
```

---

## Data Exploration

Execute these queries in Snowflake:

### Exercise 1: Explore the Data

1. Take a look at the AIRBNB database/schemas/tables (you can use the Snowflake UI for this).
2. Select 10 records from listings - review and understand the data.
3. Select 10 records from hosts - review and understand the data.
4. Select 10 records from reviews - review and understand the data.

<details>
<summary>Solution</summary>

```sql
USE AIRBNB.RAW;

SELECT * FROM RAW_LISTINGS LIMIT 10;
SELECT * FROM RAW_HOSTS LIMIT 10;
SELECT * FROM RAW_REVIEWS LIMIT 10;
```

</details>

### Exercise 2: Answer Questions with SQL

Answer the following questions by writing SQL queries:

1. Which room types are available and how many records does each type have?
2. What is the minimum and maximum value of the column `MINIMUM_NIGHTS`?
3. How many records do we have with the "minimum value" of `MINIMUM_NIGHTS`?
4. What is the minimum and maximum value of `PRICE`?
5. How many positive, negative, and neutral reviews are there?
6. What percentage of the hosts are superhosts?
7. Are there any reviews for non-existent listings?

<details>
<summary>Solution</summary>

```sql
-- 1. Room types and counts
SELECT ROOM_TYPE, COUNT(*) as NUM_RECORDS FROM RAW_LISTINGS GROUP BY ROOM_TYPE ORDER BY ROOM_TYPE;

-- 2. Min and max MINIMUM_NIGHTS
SELECT MIN(MINIMUM_NIGHTS), MAX(MINIMUM_NIGHTS) FROM RAW_LISTINGS;

-- 3. Records with minimum value of MINIMUM_NIGHTS
SELECT COUNT(*) FROM RAW_LISTINGS WHERE MINIMUM_NIGHTS = 0;

-- 4. Min and max PRICE
SELECT MIN(PRICE), MAX(PRICE) FROM RAW_LISTINGS;

-- 5. Review sentiment counts
SELECT sentiment, COUNT(*) as NUM_RECORDS FROM RAW_REVIEWS WHERE sentiment IS NOT NULL GROUP BY sentiment;

-- 6. Superhost percentage
SELECT SUM(CASE WHEN IS_SUPERHOST='t' THEN 1 ELSE 0 END)/SUM(1)* 100 as SUPERHOST_PERCENT FROM RAW_HOSTS;

-- 7. Reviews for non-existent listings
SELECT r.* FROM RAW_REVIEWS r LEFT JOIN RAW_LISTINGS l ON (r.listing_id = l.id) WHERE l.id IS NULL;
```

</details>

---

## Models

### SRC Listings (Code used in the lesson)

`models/src/src_listings.sql`:

```sql
WITH raw_listings AS (
    SELECT
        *
    FROM
        AIRBNB.RAW.RAW_LISTINGS
)
SELECT
    id AS listing_id,
    name AS listing_name,
    listing_url,
    room_type,
    minimum_nights,
    host_id,
    price AS price_str,
    created_at,
    updated_at
FROM
    raw_listings
```

### Exercise 3: SRC Reviews

Create a model which builds on top of our `raw_reviews` table.

1. Call the model `models/src/src_reviews.sql`.
2. Use a CTE (common table expression) to define an alias called `raw_reviews`. This CTE selects every column from the raw reviews table `AIRBNB.RAW.RAW_REVIEWS`.
3. In your final `SELECT`, select every column and record from `raw_reviews` and rename the following columns:
   - `date` to `review_date`.
   - `comments` to `review_text`.
   - `sentiment` to `review_sentiment`.

<details>
<summary>Solution</summary>

```sql
WITH raw_reviews AS (
    SELECT
        *
    FROM
        AIRBNB.RAW.RAW_REVIEWS
)
SELECT
    listing_id,
    date AS review_date,
    reviewer_name,
    comments AS review_text,
    sentiment AS review_sentiment
FROM
    raw_reviews
```

</details>

### Exercise 4: SRC Hosts

Create a model which builds on top of our `raw_hosts` table.

1. Call the model `models/src/src_hosts.sql`.
2. Use a CTE (common table expression) to define an alias called `raw_hosts`. This CTE selects every column from the raw hosts table `AIRBNB.RAW.RAW_HOSTS`.
3. In your final `SELECT`, select every column and record from `raw_hosts` and rename the following columns:
   - `id` to `host_id`.
   - `name` to `host_name`.

<details>
<summary>Solution</summary>

```sql
WITH raw_hosts AS (
    SELECT
        *
    FROM
        AIRBNB.RAW.RAW_HOSTS
)
SELECT
    id AS host_id,
    NAME AS host_name,
    is_superhost,
    created_at,
    updated_at
FROM
    raw_hosts
```

</details>

---

## Sources

Create a new file called `models/sources.yml`.
Add the `listings` source that points to the `raw_listings` table in the `raw` schema:

```yaml
sources:
  - name: airbnb
    schema: raw
    tables:
      - name: listings
        identifier: raw_listings
```

### Exercise 5: Add Hosts and Reviews Sources

Add the `hosts` and `reviews` sources to your `models/sources.yml` file.
Both should point to their respective raw tables (`raw_hosts` and `raw_reviews`) in the `raw` schema.

<details>
<summary>Solution</summary>

```yaml
sources:
  - name: airbnb
    schema: raw
    tables:
      - name: listings
        identifier: raw_listings

      - name: hosts
        identifier: raw_hosts

      - name: reviews
        identifier: raw_reviews
```

</details>

---

## Incremental Models

The `models/fct/fct_reviews.sql` model:
```sql
{{
  config(
    materialized = 'incremental',
    on_schema_change='fail'
    )
}}
WITH src_reviews AS (
  SELECT * FROM {{ ref('src_reviews') }}
)
SELECT * FROM src_reviews
WHERE review_text is not null

{% if is_incremental() %}
  AND review_date > (select max(review_date) from {{ this }})
{% endif %}
```

Run the model:
```sh
dbt run --select fct_reviews
```

Get every review for listing `3176` (in Snowflake):
```sql
SELECT * FROM "AIRBNB"."DEV"."FCT_REVIEWS" WHERE listing_id=3176;
```

Add a new record to the `RAW` table (in Snowflake):
```sql
INSERT INTO "AIRBNB"."RAW"."RAW_REVIEWS"
VALUES (3176, CURRENT_TIMESTAMP(), 'Zoltan', 'excellent stay!', 'positive');
```

Only add the new record:
```sh
dbt run
```

Or make a full-refresh:
```sh
dbt run --full-refresh
```

---

## Logs

Take a look at the `logs` folder (in the `airbnb` folder) to see what SQL queries were executed.

Also take a look at:

 * `target/compiled`
 * `target/run`

---

### Adding a Loaded_at Field

It's always a good idea to add a `loaded_at` field to `fct_reviews` that stores the time of record creation.

In `fct_reviews`, change
```sql
  SELECT *, current_timestamp() AS loaded_at FROM {{ ref('src_reviews') }} -- Adding loaded_at column
```

Then materialize only this model:
```sh
dbt run --full-refresh --select fct_reviews
```

## Visualizing our graph
Execute:
```sh
dbt docs generate
dbt docs serve
```

---

## Source Freshness Testing

Add freshness configuration to the `reviews` source in `models/sources.yml`:

```yaml
      - name: reviews
        identifier: raw_reviews
        config:
          loaded_at_field: date
          freshness:
            warn_after: {count: 1, period: day}
```

Check source freshness:
```sh
dbt source freshness
```

Try it with a one-minute tolerance
```yaml
            warn_after: {count: 1, period: minute}
```

---

## Cleansed Models

### DIM Listings Cleansed (Code used in the lesson)

`models/dim/dim_listings_cleansed.sql`:

```sql
WITH src_listings AS (
    SELECT * FROM {{ ref('src_listings') }}
)
SELECT
  listing_id,
  listing_name,
  room_type,
  CASE
    WHEN minimum_nights = 0 THEN 1
    ELSE minimum_nights
  END AS minimum_nights,
  host_id,
  REPLACE(
    price_str,
    '$'
  ) :: NUMBER(
    10,
    2
  ) AS price,
  created_at,
  updated_at
FROM
  src_listings
```

Materialize only `dim` models (`-s` is short for `--select`):
```sh
dbt run -s dim
```

### Exercise 6: DIM Hosts Cleansed

Create a new model in the `models/dim/` folder called `dim_hosts_cleansed.sql`.
Use a CTE to reference the `src_hosts` model.
SELECT every column and every record, and add a cleansing step to `host_name`:
- If `host_name` is not null, keep the original value.
- If `host_name` is null, replace it with the value `'Anonymous'`.
- Use the `NVL(column_name, default_null_value)` function.

<details>
<summary>Solution</summary>

```sql
WITH src_hosts AS (
    SELECT
        *
    FROM
        {{ ref('src_hosts') }}
)
SELECT
    host_id,
    NVL(
        host_name,
        'Anonymous'
    ) AS host_name,
    is_superhost,
    created_at,
    updated_at
FROM
    src_hosts
```

</details>

### Exercise 7: DIM Listings with Hosts

Create a new model in the `models/dim/` folder called `dim_listings_w_hosts.sql`.
Join `dim_listings_cleansed` with `dim_hosts_cleansed` to create a denormalized view that includes host information alongside listing data.
- Use a LEFT JOIN on `host_id`.
- Include all listing fields plus `host_name` and `is_superhost` (renamed to `host_is_superhost`).
- For `updated_at`, use the `GREATEST()` function to get the most recent update from either table.

<details>
<summary>Solution</summary>

```sql
WITH
l AS (
    SELECT
        *
    FROM
        {{ ref('dim_listings_cleansed') }}
),
h AS (
    SELECT *
    FROM {{ ref('dim_hosts_cleansed') }}
)

SELECT
    l.listing_id,
    l.listing_name,
    l.room_type,
    l.minimum_nights,
    l.price,
    l.host_id,
    h.host_name,
    h.is_superhost as host_is_superhost,
    l.created_at,
    GREATEST(l.updated_at, h.updated_at) as updated_at
FROM l
LEFT JOIN h ON (h.host_id = l.host_id)
```

</details>

### Exercise 8: View Pipeline Docs
Take a look at your pipeline by generating the docs and starting the docs server.
<details>
<summary>Solution</summary>

```sh
dbt docs generate
dbt docs serve
```

</details>

---

## Materializations

### Project-level Materialization

Set `src` models to `ephemeral` and `dim` models to `view` in `dbt_project.yml`:

```yaml
models:
  airbnb:
    src:
      +materialized: ephemeral
    dim:
      +materialized: view # This is default, but let's make it explicit
```

After setting ephemeral materialization, drop the existing src views in Snowflake:
```sql
DROP VIEW AIRBNB.DEV.SRC_HOSTS;
DROP VIEW AIRBNB.DEV.SRC_LISTINGS;
DROP VIEW AIRBNB.DEV.SRC_REVIEWS;
```

### Model-level Materialization

Set `dim_listings_w_hosts` to `table` materialization by adding a config block to the model:

`models/dim/dim_listings_w_hosts.sql`:
```sql
{{
  config(
    materialized = 'table'
  )
}}
WITH
l AS (
...
```

## Seeds

Sometimes you have smaller datasets that are not added to Snowflake by external systems and you want to add them manually. Seeds are here to the rescue:

1. Explore the `seed` folder.
2. Run `dbt seeds`.
3. Check for the table on the Snowflake UI.

### Exercise 9: Full Moon Reviews Mart

Create a mart model that analyzes whether reviews were written during a full moon. This exercise combines your `fct_reviews` model with the `seed_full_moon_dates` seed data.

**Task:** Create `models/mart/mart_fullmoon_reviews.sql` that:

1. References both `fct_reviews` and `seed_full_moon_dates` using the `{{ ref() }}` function.
2. Joins reviews with full moon dates to determine if each review was written the day after a full moon.
3. Adds a new column `is_full_moon` that contains:
   - `'full moon'` if the review was written the day after a full moon.
   - `'not full moon'` otherwise.
4. Configure the model as a `table` materialization.

**Hints:**
- Use CTEs to reference each model separately.
- Snowflake date functions you'll need:
  - `TO_DATE(timestamp_column)` - Converts a timestamp to a date (strips the time component).
  - `DATEADD(DAY, 1, date_column)` - Adds 1 day to a date (we want reviews from the day *after* the full moon).
- The join condition should match the review date with the day after the full moon date.

**Validation:** After running `dbt run --select mart_fullmoon_reviews`, query the result in Snowflake:
```sql
SELECT is_full_moon, COUNT(*) as review_count
FROM AIRBNB.DEV.MART_FULLMOON_REVIEWS
GROUP BY is_full_moon;
```

<details>
<summary>Solution</summary>

```sql
{{ config(
  materialized = 'table',
) }}

WITH fct_reviews AS (
    SELECT * FROM {{ ref('fct_reviews') }}
),
full_moon_dates AS (
    SELECT * FROM {{ ref('seed_full_moon_dates') }}
)

SELECT
  r.*,
  CASE
    WHEN fm.full_moon_date IS NULL THEN 'not full moon'
    ELSE 'full moon'
  END AS is_full_moon
FROM
  fct_reviews
  r
  LEFT JOIN full_moon_dates
  fm
  ON (TO_DATE(r.review_date) = DATEADD(DAY, 1, fm.full_moon_date))
```

</details>

### Exercise 10: Full Moon Sentiment Analysis

Create an **analysis** to investigate whether full moons affect review sentiment. Analyses are SQL files in the `analyses/` folder that are compiled but not materialized - they're useful for ad-hoc queries and reporting.

**Task:** Create `analyses/full_moon_no_sleep.sql` that:

1. References the `mart_fullmoon_reviews` model.
2. Filters out neutral sentiments (only keep `'positive'` and `'negative'`).
3. For each `is_full_moon` category, calculate:
   - `positive_count` - number of positive reviews.
   - `total_count` - total number of reviews (positive + negative).
   - `positive_percentage` - percentage of positive reviews (e.g., 85.5 for 85.5%).
4. Returns two rows: one for `'full moon'` and one for `'not full moon'`.

**Hints:**
- Use conditional aggregation: `SUM(CASE WHEN condition THEN 1 ELSE 0 END)` counts matching rows.
- Snowflake integer division truncates decimals - multiply by `100.0` to get a percentage.
- Use `ROUND(value, 2)` to round to 2 decimal places for cleaner output.

**Run the analysis:**
```sh
dbt show --select full_moon_no_sleep
```

<details>
<summary>Solution</summary>

```sql
WITH fullmoon_reviews AS (
    SELECT * FROM {{ ref('mart_fullmoon_reviews') }}
)
SELECT
    is_full_moon,
    SUM(CASE WHEN review_sentiment = 'positive' THEN 1 ELSE 0 END) AS positive_count,
    COUNT(*) AS total_count,
    ROUND(SUM(CASE WHEN review_sentiment = 'positive' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS positive_percentage
FROM
    fullmoon_reviews
WHERE
    review_sentiment != 'neutral'
GROUP BY
    is_full_moon
ORDER BY
    is_full_moon
```

</details>

---

## Snapshots

Snapshots implement tracking of slowly changing dimensions (see [Slowly changing dimension — Type 2 (SCD2)](https://en.wikipedia.org/wiki/Slowly_changing_dimension#Type_2)).

### Snapshots for Listings
The contents of `snapshots/snapshots.yml`:
```yaml
snapshots:
  - name: scd_raw_listings
    relation: source('airbnb', 'listings')
    config:
      unique_key: id
      strategy: timestamp
      updated_at: updated_at
      hard_deletes: invalidate
```

Materialize the snapshot:
```sh
dbt snapshot
```

Take a look at a single record:
```sql
SELECT * FROM AIRBNB.DEV.SCD_RAW_LISTINGS WHERE ID=3176;
```

### Updating the table
```sql
SELECT * FROM AIRBNB.RAW.RAW_LISTINGS WHERE ID=3176;
```

```sql
UPDATE AIRBNB.RAW.RAW_LISTINGS SET MINIMUM_NIGHTS=30,
    updated_at=CURRENT_TIMESTAMP() WHERE ID=3176;
```

```sql
SELECT * FROM AIRBNB.RAW.RAW_LISTINGS WHERE ID=3176;
```

Run `dbt snapshot` again.

Let's see the changes:
```sql
SELECT * FROM AIRBNB.DEV.SCD_RAW_LISTINGS WHERE ID=3176;
```


### Building everything with the same command
```sh
dbt build
```

### Exercise 11: SCD Raw Hosts Snapshot
1. Create a snapshot for `raw_hosts`.
2. Run it.
3. Update `raw_hosts`.
4. Run snapshot again.
5. Validate the change in the snapshot.
<details>
<summary>Solution</summary>

Add this to `snapshots/snapshots.yml`:
```yaml
snapshots:
  - name: scd_raw_hosts
    relation: source('airbnb', 'hosts')
    config:
      unique_key: id
      strategy: timestamp
      updated_at: updated_at
      hard_deletes: invalidate
```
</details>

## Tests

### Data Tests

#### Generic Data Tests
The contents of `models/schema.yml`:

```yaml
models:
  - name: dim_listings_cleansed
    columns:
      - name: listing_id
        data_tests:
          - unique
          - not_null

      - name: host_id
        data_tests:
          - not_null
          - relationships:
              arguments:
                to: ref('dim_hosts_cleansed')
                field: host_id

      - name: room_type
        data_tests:
          - accepted_values:
              arguments:
                values: ['Entire home/apt',
                         'Private room',
                         'Shared room',
                         'Hotel room']
```

### Singular Data Tests
#### Singular Test for Minimum Nights Check
The contents of `tests/dim_listings_minimum_nights.sql`:

```sql
SELECT
    *
FROM
    {{ ref('dim_listings_cleansed') }}
WHERE minimum_nights < 1
LIMIT 10
```

#### Restricting test execution to a specific test
```sh
dbt test -s dim_listings_minimum_nights
```

### Unit Tests
Add this to `models/mart/unit_tests.yml`:
```yml
unit_tests:
  - name: unittest_fullmoon_matcher
    model: mart_fullmoon_reviews
    given:
      - input: ref('fct_reviews')
        rows:
          - {review_date: '2025-01-13'}
          - {review_date: '2025-01-14'}
          - {review_date: '2025-01-15'}
      - input: ref('seed_full_moon_dates')
        rows:
          - {full_moon_date: '2025-01-14'}
    expect:
      rows:
        - {review_date: '2025-01-13', is_full_moon: "not full moon"}
        - {review_date: '2025-01-14', is_full_moon: "not full moon"}
        - {review_date: '2025-01-15', is_full_moon: "full moon"}
```

### Restricting test execution to tests associated with a specific model
```sh
dbt test -s mart_fullmoon_reviews
```

### Setting Severity
Let's test if the sentiment is not null in our sources, but we don't want the test to fail the whole test workflow, only to give a warning.

Add the sentiment column definition to `models/sources.yml`:
```
sources:
  - name: airbnb
    schema: raw
    tables:
      - name: listings
        identifier: raw_listings
      - name: hosts
        identifier: raw_hosts
      - name: reviews
        identifier: raw_reviews
        columns:
          - name: sentiment
            tests:
              - not_null:
                  config:
                    severity: warn
        config:
          loaded_at_field: date
          freshness:
            warn_after: {count: 1, period: minute}
```

Execute `dbt test -s 'source:airbnb.reviews'` to run the test only on this column

### Storing Test Failures
Add this to your `dbt_project.yml`:

```
data_tests:
  +store_failures: true
  +schema: _test_failures
```

### Taking Testing in Production
Here is the link to [Elementary Data](https://www.elementary-data.com/) if you want to take testing to the next level.

### Exercise 12: Generic Tests for dim_hosts_cleansed

Create generic data tests for the `dim_hosts_cleansed` model in `models/schema.yml`:

- `host_id`: Should be unique and not contain null values.
- `host_name`: Should not contain any null values.
- `is_superhost`: Should only contain the values `'t'` and `'f'`.

Execute `dbt test` to verify that your tests are passing.

<details>
<summary>Solution</summary>

Add this to `models/schema.yml`:

```yaml
  - name: dim_hosts_cleansed
    columns:
      - name: host_id
        data_tests:
          - not_null
          - unique

      - name: host_name
        data_tests:
          - not_null

      - name: is_superhost
        data_tests:
          - accepted_values:
              arguments:
                values: ['t', 'f']
```

</details>

### Exercise 13: Singular Test for Consistent Created Dates

Create a singular test in `tests/consistent_created_at.sql` that checks that there is no review date that is submitted before its listing was created.

Make sure that every `review_date` in `fct_reviews` is more recent than the associated `created_at` in `dim_listings_cleansed`.

**Hints:**
- Use an INNER JOIN between the two tables on `listing_id`.
- Filter for rows where `created_at > review_date` (these are the problematic records).
- Remember: singular tests should return rows that FAIL the test.

<details>
<summary>Solution</summary>

`tests/consistent_created_at.sql`:

```sql
SELECT * FROM {{ ref('dim_listings_cleansed') }} l
INNER JOIN {{ ref('fct_reviews') }} r
USING (listing_id)
WHERE l.created_at > r.review_date
```

</details>

### Exercise 14: Setting Test Severity to Warn

Historically, review and listing date mismatch is a known data quality issue that we want to monitor but not block our pipeline, configure this test to emit a **warning** instead of an **error**.

Add a config block to the test file (`tests/consistent_created_at.sql`):

```sql
{{
  config(
    severity = 'warn'
  )
}}
```

But when you run these tests, it actually passes, right? Simulate failure by flipping the relation and testing for `l.created_at <= r.review_date`. Once you confirmed that the test would give a warning, **revert this change** so that the test passes again.

<details>
<summary>Solution</summary>

```sql
{{
  config(
    severity = 'warn'
  )
}}

SELECT * FROM {{ ref('dim_listings_cleansed') }} l
INNER JOIN {{ ref('fct_reviews') }} r
USING (listing_id)
WHERE l.created_at <= r.review_date
```

</details>

---

## Third-party Packages

dbt packages are reusable modules that extend dbt's functionality. You can find packages on the [dbt Hub](https://hub.getdbt.com/).

### Adding dbt_utils

[dbt_utils](https://hub.getdbt.com/dbt-labs/dbt_utils/latest/) provides useful macros for SQL generation.

1. Create `packages.yml` in your project root:
   ```yaml
   packages:
     - package: dbt-labs/dbt_utils
       version: 1.3.3
   ```

2. Install dependencies:
   ```sh
   dbt deps
   ```

### Using Surrogate Keys

Update `models/fct/fct_reviews.sql` to generate a surrogate key:

```sql
{{
  config(
    materialized = 'incremental',
    on_schema_change='fail'
    )
}}

WITH src_reviews AS (
  SELECT * FROM {{ ref('src_reviews') }}
)
SELECT
  {{ dbt_utils.generate_surrogate_key(['listing_id', 'review_date', 'reviewer_name', 'review_text']) }} as review_id,
  *,
  current_timestamp() AS loaded_at
FROM src_reviews
WHERE review_text is not null
{% if is_incremental() %}
  AND review_date > (select max(review_date) from {{ this }})
{% endif %}
```

Run the model:
```sh
dbt run --select fct_reviews
```

This will **fail** because the schema changed (new column added) and `on_schema_change='fail'` is set.

To rebuild from scratch:
```sh
dbt run --select fct_reviews --full-refresh
```

### Exercise 15: Add dbt-expectations

[dbt-expectations](https://github.com/metaplane/dbt-expectations) is a package that provides additional data quality tests inspired by Great Expectations.

1. Add dbt-expectations to `packages.yml`.
2. Run `dbt deps`.
3. Add a test using [expect_column_to_exist](https://github.com/metaplane/dbt-expectations?tab=readme-ov-file#expect_column_to_exist) on the `review_id` column in `models/schema.yml`.
4. Run `dbt test --select fct_reviews`.

<details>
<summary>Solution</summary>

`packages.yml`:
```yaml
packages:
  - package: dbt-labs/dbt_utils
    version: 1.3.3
  - package: metaplane/dbt_expectations
    version: 0.10.10
```

Add to `models/schema.yml`:
```yaml
  - name: fct_reviews
    columns:
      - name: review_id
        data_tests:
          - dbt_expectations.expect_column_to_exist
```

</details>

---

## Documentation

dbt allows you to document your models and columns directly in the project using docs blocks and schema.yml descriptions.

### Documenting Models in schema.yml

Add descriptions directly to the `dim_listings_cleansed` model in `models/schema.yml`:

```yaml
  - name: dim_listings_cleansed
    description: Cleansed table which contains Airbnb listings.
    columns:
      - name: listing_id
        description: Primary key for the listing
        data_tests:
          - unique
          - not_null

      - name: host_id
        description: The host's id. References the host table.
        data_tests:
          - not_null
          - relationships:
              arguments:
                to: ref('dim_hosts_cleansed')
                field: host_id
```

### Viewing the Documentation

Generate and serve the documentation:
```sh
dbt docs generate
dbt docs serve
```

### Documenting Columns with Docs Blocks

Create a new file `models/docs.md` with a docs block for the `minimum_nights` column:

```md
{% docs dim_listing_cleansed__minimum_nights %}
Minimum number of nights required to rent this property.

Keep in mind that old listings might have `minimum_nights` set to 0 in the source tables. Our cleansing algorithm updates this to `1`.

{% enddocs %}
```

Reference this documentation in `models/schema.yml` by adding a description to the `minimum_nights` column under `dim_listings_cleansed`:

```yaml
      - name: minimum_nights
        description: '{{ doc("dim_listing_cleansed__minimum_nights") }}'
```

### Landing Page

You can customize the landing page of your dbt documentation by creating a special docs block named `__overview__`.

Create or update `models/overview.md`:

```md
{% docs __overview__ %}
# Airbnb pipeline

Hey, welcome to our Airbnb pipeline documentation!

{% enddocs %}
```

### Exercise 16: Document dim_hosts_cleansed

Add documentation to `dim_hosts_cleansed` in `models/schema.yml`:

1. Add a model-level `description` for `dim_hosts_cleansed`: "Cleansed table which contains Airbnb hosts."
2. Add descriptions for the following columns:
   - `host_id`: "Primary key for the host".
   - `host_name`: "The name of the host".
   - `is_superhost`: "Whether the host is a superhost".
3. Create a docs block in `models/docs.md` for the `host_name` column called `dim_hosts_cleansed__host_name` that explains the cleansing process replaces null host names with 'Anonymous'.
4. Reference this docs block in the `host_name` column description.
5. Run `dbt docs generate && dbt docs serve` to view your documentation.

<details>
<summary>Solution</summary>

Add to `models/docs.md`:
```md
{% docs dim_hosts_cleansed__host_name %}
The name of the host.

If the host name was null in the source data, our cleansing process replaces it with 'Anonymous'.

{% enddocs %}
```

Update `models/schema.yml` under `dim_hosts_cleansed`:
```yaml
  - name: dim_hosts_cleansed
    description: Cleansed table which contains Airbnb hosts.
    columns:
      - name: host_id
        description: Primary key for the host
        data_tests:
          - not_null
          - unique

      - name: host_name
        description: '{{ doc("dim_hosts_cleansed__host_name") }}'
        data_tests:
          - not_null

      - name: is_superhost
        description: Whether the host is a superhost
        data_tests:
          - accepted_values:
              arguments:
                values: ['t', 'f']
```

</details>
