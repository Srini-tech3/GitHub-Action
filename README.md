# Terraform AWS S3 Upload

This project sets up an AWS S3 bucket with non-public access, creates a subfolder, and uploads a specified file from a local Windows folder to the S3 bucket using Terraform.

## Project Structure

```
terraform-aws-s3-upload
├── main.tf
├── variables.tf
├── outputs.tf
├── provider.tf
└── README.md
```

## Prerequisites

- Terraform installed on your local machine.
- AWS account with appropriate permissions to create S3 buckets and upload files.
- AWS CLI configured with your credentials.

## Configuration

1. **Edit `variables.tf`**: Update the variables for `bucket_name`, `region`, and `local_file_path` to match your desired configuration.

2. **Initialize Terraform**: Run the following command in your terminal to initialize the Terraform configuration:

   ```
   terraform init
   ```

3. **Plan the Deployment**: To see what resources will be created, run:

   ```
   terraform plan
   ```

4. **Apply the Configuration**: To create the S3 bucket and upload the file, run:

   ```
   terraform apply
   ```

   Confirm the action when prompted.

## Outputs

After the deployment is complete, the following outputs will be displayed:

- `bucket_name`: The name of the created S3 bucket.
- `uploaded_file_url`: The URL of the uploaded file in the S3 bucket.

## Cleanup

To remove the resources created by this project, run:

```
terraform destroy
```

This will delete the S3 bucket and any uploaded files.