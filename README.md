# Date Picking and Backfilling System

## Overview

The **Date Picking and Backfilling System** is a scalable and flexible system designed to automate and manage data pipeline executions. It tracks and processes complex scheduling patterns, manages backfills for missing or outdated data, and integrates with various data platforms such as **Databricks**, **DBT**, and **Snowflake**.

### Key Features
- **Flexible Date Scheduling**: Handles daily, weekly, and monthly scheduling with multi-date and offset capabilities.
- **Backfilling**: Automatically manages backfilling tasks for missing data, including retries and prioritization.
- **SLA Monitoring**: Tracks and enforces SLAs, triggering notifications for any SLA breaches.
- **Data Quality Monitoring**: Integrates with data quality checks to ensure pipeline outputs are accurate and consistent.
- **Retry Mechanism**: Automatically retries failed pipeline runs, including backfill runs.


## Database Schema

Below is the structure of the database used for the system. The schema is designed to track the state and details of each pipeline run, manage backfill tasks, and monitor data quality and SLA compliance.
![de-backfill-engine.png](img%2Fde-backfill-engine.png)
```dbml
Table pipelines {
  pipeline_id            VARCHAR [pk, unique, not null]
  pipeline_name          VARCHAR
  platform               VARCHAR
  trigger_url            TEXT
  platform_job_id        VARCHAR
  schedule_type          VARCHAR
  frequency              VARCHAR
  date_offset            INT
  multi_date_allowed     BOOLEAN
  retry_enabled          BOOLEAN
  retry_schedule         VARCHAR
  max_retry_attempts     INT
  auto_backfill          BOOLEAN
  notification_channel   VARCHAR
  notification_details   TEXT
  data_quality_check     BOOLEAN
  sla_time               TIME
  sla_breach_notification BOOLEAN
  created_at             TIMESTAMP
  updated_at             TIMESTAMP
}

Table pipeline_run_log {
  run_id               VARCHAR [pk, unique, not null]
  pipeline_id          VARCHAR [ref: > pipelines.pipeline_id]
  run_date             DATE
  status               VARCHAR
  start_time           TIMESTAMP
  end_time             TIMESTAMP
  retry_attempts       INT
  retry_schedule_used  VARCHAR
  error_message        TEXT
  data_quality_passed  BOOLEAN
  is_backfill          BOOLEAN
  sla_met              BOOLEAN
  backfill_id          VARCHAR [ref: > backfill_queue.backfill_id, null]
}

Table pipeline_parameters {
  parameter_id         VARCHAR [pk, unique, not null]
  pipeline_id          VARCHAR [ref: > pipelines.pipeline_id]
  parameter_name       VARCHAR
  parameter_value      TEXT
  created_at           TIMESTAMP
}

Table backfill_queue {
  backfill_id          VARCHAR [pk, unique, not null]
  pipeline_id          VARCHAR [ref: > pipelines.pipeline_id]
  date_to_process      DATE
  status               VARCHAR
  retry_attempts       INT
  priority             INT
  requested_at         TIMESTAMP
}

Table data_quality_log {
  quality_check_id     VARCHAR [pk, unique, not null]
  run_id               VARCHAR [ref: > pipeline_run_log.run_id]
  check_name           VARCHAR
  check_result         BOOLEAN
  error_details        TEXT
  created_at           TIMESTAMP
}

Table pipeline_notifications {
  notification_id      VARCHAR [pk, unique, not null]
  pipeline_id          VARCHAR [ref: > pipelines.pipeline_id]
  run_id               VARCHAR [ref: > pipeline_run_log.run_id]
  notification_type    VARCHAR
  notification_status  VARCHAR
  sent_at              TIMESTAMP
  notification_channel VARCHAR
}

