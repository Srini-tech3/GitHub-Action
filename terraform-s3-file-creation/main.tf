# Generate unique suffix
resource "random_id" "suffix" {
  byte_length = 4
}

# Raw S3 Bucket
resource "aws_s3_bucket" "raw" {
  bucket = "${var.raw_bucket_name}-${random_id.suffix.hex}"
}

# Processed S3 Bucket
resource "aws_s3_bucket" "processed" {
  bucket = "${var.processed_bucket_name}-${random_id.suffix.hex}"
}

# Script S3 Bucket
resource "aws_s3_bucket" "script" {
  bucket = "${var.script_bucket_name}-${random_id.suffix.hex}"
}


# Upload CSV to raw bucket
resource "aws_s3_object" "raw_file" {
  bucket = aws_s3_bucket.raw.id
  key    = "${var.subfolder}/${basename(var.local_file_path)}"
  source = var.local_file_path
  acl    = "private"
}

# Upload Script to script bucket
resource "aws_s3_object" "glue_script" {
  bucket = aws_s3_bucket.script.id
  key    = "${var.script_subfolder}/${basename(var.script_location)}"
  source = var.script_location
  acl    = "private"
}


# Glue IAM Role
resource "aws_iam_role" "glue_role" {
  name = "glue-role-sit"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "glue.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Glue Database
resource "aws_glue_catalog_database" "iceberg_db" {
  name = "sit_iceberg_db"
}

# Glue Iceberg Table
resource "aws_glue_catalog_table" "iceberg_table" {
  name          = "employee_data"
  database_name = aws_glue_catalog_database.iceberg_db.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "table_type"                 = "ICEBERG"
    "classification"             = "iceberg"
    "EXTERNAL"                   = "TRUE"
    "projection.enabled"         = "false"
    "write_compression"          = "snappy"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.processed.bucket}/iceberg/transactions/"
    input_format  = "org.apache.iceberg.mr.hive.HiveIcebergInputFormat"
    output_format = "org.apache.iceberg.mr.hive.HiveIcebergOutputFormat"

    ser_de_info {
      name                  = "iceberg-serde"
      serialization_library = "org.apache.iceberg.mr.hive.HiveIcebergSerDe"
    }
 
  }
}

# Glue Job
resource "aws_glue_job" "etl_job" {
  name     = var.glue_job_name
  role_arn = aws_iam_role.glue_role.arn
  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.script.bucket}/${aws_s3_object.glue_script.key}"
    python_version  = "3"
  }
  default_arguments = {
    "--TempDir"             = "s3://${aws_s3_bucket.processed.bucket}/temp/"
    "--SOURCE_BUCKET"       = aws_s3_bucket.raw.bucket
    "--PROCESSED_BUCKET"    = aws_s3_bucket.processed.bucket
    "--ICEBERG_WAREHOUSE"   = "s3://${aws_s3_bucket.processed.bucket}/iceberg/"
    "--DB_NAME"             = aws_glue_catalog_database.iceberg_db.name
    "--TABLE_NAME"          = "employee_data"
  }
  glue_version       = "3.0"
  number_of_workers  = 2
  worker_type        = "G.1X"
}

resource "aws_glue_job_run" "run_etl" {
  depends_on = [aws_glue_job.etl_job]
  job_name   = aws_glue_job.etl_job.name
}

resource "null_resource" "wait_glue_job" {
  depends_on = [aws_glue_job_run.run_etl]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = <<EOT
      JOB_NAME="${aws_glue_job.etl_job.name}"
      RUN_ID="${aws_glue_job_run.run_etl.id}"
      REGION="${var.aws_region}"
      
      echo "⏳ Waiting for Glue job $JOB_NAME to complete..."
      STATUS=""
      
      while [ "$STATUS" != "SUCCEEDED" ] && [ "$STATUS" != "FAILED" ] && [ "$STATUS" != "STOPPED" ]; do
          STATUS=$(aws glue get-job-run \
            --job-name "$JOB_NAME" \
            --run-id "$RUN_ID" \
            --region "$REGION" \
            --query "JobRun.JobRunState" \
            --output text)
          echo "Current Glue Job status: $STATUS"
          sleep 30
      done

      if [ "$STATUS" != "SUCCEEDED" ]; then
          echo "❌ Glue job failed with status: $STATUS"
          exit 1
      else
          echo "✅ Glue job completed successfully!"
      fi
    EOT
  }
}
