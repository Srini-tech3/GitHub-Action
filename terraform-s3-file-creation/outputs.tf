# S3 Buckets
output "raw_bucket_name" {
  description = "Name of the raw S3 bucket"
  value       = aws_s3_bucket.raw.bucket
}

output "processed_bucket_name" {
  description = "Name of the processed S3 bucket"
  value       = aws_s3_bucket.processed.bucket
}

output "script_bucket_name" {
  description = "Name of the script S3 bucket"
  value       = aws_s3_bucket.script.bucket
}

# Uploaded Objects
output "uploaded_csv_key" {
  description = "S3 key of the uploaded CSV file"
  value       = aws_s3_object.raw_file.key
}

output "uploaded_script_key" {
  description = "S3 key of the uploaded Glue script"
  value       = aws_s3_object.glue_script.key
}

# Glue
output "glue_database_name" {
  description = "Glue database name for Iceberg"
  value       = aws_glue_catalog_database.iceberg_db.name
}

output "glue_table_name" {
  description = "Glue Iceberg table name"
  value       = aws_glue_catalog_table.iceberg_table.name
}

output "glue_job_name" {
  description = "Glue ETL job name"
  value       = aws_glue_job.etl_job.name
}

output "glue_job_role_arn" {
  description = "IAM Role ARN used by Glue Job"
  value       = aws_iam_role.glue_role.arn
}
