CREATE TABLE `pipelines` (
  `pipeline_id` VARCHAR UNIQUE PRIMARY KEY NOT NULL,
  `pipeline_name` VARCHAR,
  `platform` VARCHAR,
  `trigger_url` TEXT,
  `platform_job_id` VARCHAR,
  `schedule_type` VARCHAR,
  `frequency` VARCHAR,
  `date_offset` INT,
  `multi_date_allowed` BOOLEAN,
  `retry_enabled` BOOLEAN,
  `retry_schedule` VARCHAR,
  `max_retry_attempts` INT,
  `auto_backfill` BOOLEAN,
  `notification_channel` VARCHAR,
  `notification_details` TEXT,
  `data_quality_check` BOOLEAN,
  `sla_time` TIME,
  `sla_breach_notification` BOOLEAN,
  `created_at` TIMESTAMP,
  `updated_at` TIMESTAMP
);

CREATE TABLE `pipeline_run_log` (
  `run_id` VARCHAR UNIQUE PRIMARY KEY NOT NULL,
  `pipeline_id` VARCHAR,
  `run_date` DATE,
  `status` VARCHAR,
  `start_time` TIMESTAMP,
  `end_time` TIMESTAMP,
  `retry_attempts` INT,
  `retry_schedule_used` VARCHAR,
  `error_message` TEXT,
  `data_quality_passed` BOOLEAN,
  `is_backfill` BOOLEAN,
  `sla_met` BOOLEAN,
  `backfill_id` VARCHAR
);

CREATE TABLE `pipeline_parameters` (
  `parameter_id` VARCHAR UNIQUE PRIMARY KEY NOT NULL,
  `pipeline_id` VARCHAR,
  `parameter_name` VARCHAR,
  `parameter_value` TEXT,
  `created_at` TIMESTAMP
);

CREATE TABLE `backfill_queue` (
  `backfill_id` VARCHAR UNIQUE PRIMARY KEY NOT NULL,
  `pipeline_id` VARCHAR,
  `date_to_process` DATE,
  `status` VARCHAR,
  `retry_attempts` INT,
  `priority` INT,
  `requested_at` TIMESTAMP
);

CREATE TABLE `data_quality_log` (
  `quality_check_id` VARCHAR UNIQUE PRIMARY KEY NOT NULL,
  `run_id` VARCHAR,
  `check_name` VARCHAR,
  `check_result` BOOLEAN,
  `error_details` TEXT,
  `created_at` TIMESTAMP
);

CREATE TABLE `pipeline_notifications` (
  `notification_id` VARCHAR UNIQUE PRIMARY KEY NOT NULL,
  `pipeline_id` VARCHAR,
  `run_id` VARCHAR,
  `notification_type` VARCHAR,
  `notification_status` VARCHAR,
  `sent_at` TIMESTAMP,
  `notification_channel` VARCHAR
);

ALTER TABLE `pipeline_run_log` ADD FOREIGN KEY (`pipeline_id`) REFERENCES `pipelines` (`pipeline_id`);

ALTER TABLE `pipeline_run_log` ADD FOREIGN KEY (`backfill_id`) REFERENCES `backfill_queue` (`backfill_id`);

ALTER TABLE `pipeline_parameters` ADD FOREIGN KEY (`pipeline_id`) REFERENCES `pipelines` (`pipeline_id`);

ALTER TABLE `backfill_queue` ADD FOREIGN KEY (`pipeline_id`) REFERENCES `pipelines` (`pipeline_id`);

ALTER TABLE `data_quality_log` ADD FOREIGN KEY (`run_id`) REFERENCES `pipeline_run_log` (`run_id`);

ALTER TABLE `pipeline_notifications` ADD FOREIGN KEY (`pipeline_id`) REFERENCES `pipelines` (`pipeline_id`);

ALTER TABLE `pipeline_notifications` ADD FOREIGN KEY (`run_id`) REFERENCES `pipeline_run_log` (`run_id`);
