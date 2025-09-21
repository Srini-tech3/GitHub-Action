variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "raw_bucket_name" {
  type        = string
  description = "S3 bucket for raw data"
}

variable "processed_bucket_name" {
  type        = string
  description = "S3 bucket for processed data"
}

variable "glue_job_name" {
  type        = string
  description = "Glue ETL job name"
}

variable "subfolder" {
  type        = string
  description = "Subfolder in S3 bucket for uploaded files"
}

variable "local_file_path" {
  type        = string
  description = "Path to local CSV file to upload"
}
variable "script_bucket_name" {
  type        = string
  description = "S3 bucket for Glue scripts"
}

variable "script_location" {
  type        = string
  description = "Path to local script file to upload"
}

variable "script_subfolder" {
  type        = string
  description = "Subfolder in script S3 bucket for Glue scripts"
}

