# Automated BackFilling Model For Big Data Pipelines

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
```

## Tables Overview

### 1. **pipelines**
This table stores configuration metadata for each data pipeline, including scheduling details, platform information, and retry/backfill configurations.

#### Columns:
- **pipeline_id**: Unique identifier for the pipeline.
- **pipeline_name**: Name of the pipeline.
- **platform**: Platform where the pipeline runs (e.g., Databricks, DBT, Snowflake).
- **trigger_url**: URL to manually or automatically trigger the pipeline.
- **platform_job_id**: Platform-specific job identifier (e.g., Databricks job ID).
- **schedule_type**: Type of schedule (e.g., 'daily', 'weekly', 'monthly').
- **frequency**: Frequency of the pipeline run (e.g., 'every 1 day', 'every 1 week').
- **date_offset**: Offset for scheduling the pipeline run.
- **multi_date_allowed**: Whether the pipeline can process multiple dates per run.
- **retry_enabled**: Indicates if retries are enabled for this pipeline.
- **retry_schedule**: Retry schedule (e.g., retry every 5 minutes).
- **max_retry_attempts**: Maximum retry attempts before marking the run as failed.
- **auto_backfill**: Whether the pipeline supports automatic backfilling.
- **notification_channel**: Communication channel for sending notifications.
- **notification_details**: Specific notification configuration (e.g., Slack, email).
- **data_quality_check**: Whether a data quality check is performed.
- **sla_time**: SLA time by which the pipeline must complete.
- **sla_breach_notification**: Notification trigger if SLA is breached.
- **created_at**: Timestamp when the pipeline was created.
- **updated_at**: Timestamp when the pipeline configuration was last updated.

### 2. **pipeline_run_log**
This table records detailed metadata about each execution of a pipeline, including status, timestamps, retries, and data quality checks.

#### Columns:
- **run_id**: Unique identifier for the pipeline run.
- **pipeline_id**: Foreign key referencing the `pipelines` table.
- **run_date**: Date when the pipeline was executed.
- **status**: Status of the pipeline run (e.g., 'success', 'failed').
- **start_time**: Start timestamp for the pipeline run.
- **end_time**: End timestamp for the pipeline run.
- **retry_attempts**: Number of retries made for this run.
- **retry_schedule_used**: Retry schedule applied.
- **error_message**: Error details in case of failure.
- **data_quality_passed**: Whether the data passed the quality checks.
- **is_backfill**: Whether this run is a backfill.
- **sla_met**: Whether the pipeline met its SLA.
- **backfill_id**: Foreign key to the `backfill_queue` if this was a backfill run.

### 3. **pipeline_parameters**
This table stores the parameters used for configuring the pipeline during each run. These can include paths, dates, or environment-specific settings.

#### Columns:
- **parameter_id**: Unique identifier for the parameter.
- **pipeline_id**: Foreign key referencing the `pipelines` table.
- **parameter_name**: Name of the parameter.
- **parameter_value**: Value of the parameter.
- **created_at**: Timestamp when the parameter was created.

### 4. **backfill_queue**
The `backfill_queue` table stores the backfill requests. Each record represents a date that needs to be processed due to missing or outdated data.

#### Columns:
- **backfill_id**: Unique identifier for the backfill task.
- **pipeline_id**: Foreign key referencing the `pipelines` table.
- **date_to_process**: The date that needs to be backfilled.
- **status**: Status of the backfill (e.g., 'pending', 'in_progress').
- **retry_attempts**: Number of retry attempts for this backfill.
- **priority**: Priority of the backfill (higher values indicate higher priority).
- **requested_at**: Timestamp when the backfill was requested.

### 5. **data_quality_log**
This table records the results of data quality checks performed on each pipeline run. It tracks whether the data meets the predefined quality standards.

#### Columns:
- **quality_check_id**: Unique identifier for the data quality check.
- **run_id**: Foreign key referencing the `pipeline_run_log`.
- **check_name**: Name of the data quality check.
- **check_result**: Result of the check (true/false).
- **error_details**: Details about any error or failure.
- **created_at**: Timestamp when the quality check was performed.

### 6. **pipeline_notifications**
This table stores notifications sent related to pipeline runs. It tracks the notification type, status, and whether any SLA breaches occurred.

#### Columns:
- **notification_id**: Unique identifier for the notification.
- **pipeline_id**: Foreign key referencing the `pipelines` table.
- **run_id**: Foreign key referencing the `pipeline_run_log`.
- **notification_type**: Type of notification (e.g., 'SLA breach', 'failure', 'success').
- **notification_status**: Status of the notification (e.g., 'sent', 'pending').
- **sent_at**: Timestamp when the notification was sent.
- **notification_channel**: Communication channel used for the notification (e.g., Slack, email).

---

## System Flow

1. **Pipeline Configuration**:
   - Users configure pipelines in the `pipelines` table, specifying when and how the pipeline should run, whether retries and backfills are enabled, and setting up notification channels.

2. **Pipeline Execution**:
   - Based on the defined schedule in the `pipelines` table, the pipeline is triggered. A record of the run is logged in the `pipeline_run_log` table.

3. **Backfilling**:
   - If there is missing or outdated data, the backfill queue (`backfill_queue`) is populated. Backfill tasks are tracked here and processed based on priority. The pipeline run is then logged in the `pipeline_run_log` with an indicator (`is_backfill`).

4. **Data Quality Check**:
   - After each pipeline run, data quality checks are performed. Results of these checks are logged in the `data_quality_log` table to ensure data integrity.

5. **Notifications**:
   - After each run, the system checks if any SLA was breached or if there were failures. Notifications are sent accordingly and logged in the `pipeline_notifications` table.
