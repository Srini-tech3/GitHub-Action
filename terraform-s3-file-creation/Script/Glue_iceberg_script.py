import sys
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql import SparkSession

# ---------------------------
# Accept arguments from Glue job
# ---------------------------
args = getResolvedOptions(
    sys.argv,
    ["JOB_NAME", "SOURCE_BUCKET", "PROCESSED_BUCKET", "ICEBERG_WAREHOUSE", "DB_NAME", "TABLE_NAME"]
)

# Initialize Spark + Glue
spark = SparkSession.builder.appName(args["JOB_NAME"]).getOrCreate()
glueContext = GlueContext(spark)
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# ---------------------------
# Configure Iceberg Catalog
# ---------------------------
spark.conf.set("spark.sql.catalog.glue_catalog", "org.apache.iceberg.spark.SparkCatalog")
spark.conf.set("spark.sql.catalog.glue_catalog.catalog-impl", "org.apache.iceberg.aws.glue.GlueCatalog")
spark.conf.set("spark.sql.catalog.glue_catalog.warehouse", args["ICEBERG_WAREHOUSE"])
spark.conf.set("spark.sql.catalog.glue_catalog.io-impl", "org.apache.iceberg.aws.s3.S3FileIO")

# ---------------------------
# Read source data (dynamic)
# ---------------------------
file_path = f"s3://{args['SOURCE_BUCKET']}/csv/employee_data.csv"
df = spark.read.csv(file_path, header=True, inferSchema=True)

# ---------------------------
# Write to Iceberg Table
# ---------------------------
table_name = f"glue_catalog.{args['DB_NAME']}.{args['TABLE_NAME']}"

df.writeTo(table_name) \
    .using("iceberg") \
    .tableProperty("format-version", "2") \
    .createOrReplace()

print(f"✅ Iceberg table write successful: {table_name}")

job.commit()
