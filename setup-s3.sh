#!/bin/bash

# Function to check if AWS CLI is installed and install it if necessary
check_aws_cli() {
    # Check if the 'aws' command is available in the system
    if ! command -v aws &> /dev/null; then
        echo "AWS CLI not found. Installing AWS CLI..."
        
        # Download the AWS CLI installation package
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        
        # Unzip the downloaded file
        unzip awscliv2.zip
        
        # Install AWS CLI using sudo privileges
        sudo ./aws/install
        
        # Clean up by removing unnecessary installation files
        rm -rf aws awscliv2.zip
        
        echo "AWS CLI installed successfully."
    else
        echo "AWS CLI is already installed."
    fi
}

# Function to configure AWS CLI with user-provided credentials
configure_aws() {
    echo "Configuring AWS CLI..."
    # Run the interactive AWS CLI configuration command
    aws configure
}

# Function to create an S3 bucket securely
create_s3_bucket() {
    local bucket_name=$1  # First argument: Name of the S3 bucket
    local region=$2       # Second argument: AWS region
    
    echo "Creating S3 bucket: $bucket_name in region: $region..."
    # Create an S3 bucket using AWS CLI
    aws s3api create-bucket --bucket "$bucket_name" --region "$region"
    
    # Check if the bucket creation was successful
    if [ $? -eq 0 ]; then
        echo "Bucket created successfully: $bucket_name"
    else
        echo "Failed to create bucket."
        exit 1  # Exit script if bucket creation fails
    fi
    
    # Apply security settings to block public access to the bucket
    aws s3api put-public-access-block --bucket "$bucket_name" \
        --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
    
    echo "Bucket secured: Public access blocked."
}

# Function to upload a file to an S3 bucket
upload_file() {
    local file_path=$1    # First argument: Path to the file to be uploaded
    local bucket_name=$2  # Second argument: S3 bucket name
    
    echo "Uploading file: $file_path to S3 bucket: $bucket_name..."
    # Use AWS CLI to copy the file to the specified S3 bucket
    aws s3 cp "$file_path" "s3://$bucket_name/"
    
    # Check if the upload was successful
    if [ $? -eq 0 ]; then
        echo "File uploaded successfully."
    else
        echo "File upload failed."
        exit 1  # Exit script if upload fails
    fi
}

# Function to generate a pre-signed URL for an S3 object (file)
generate_presigned_url() {
    local bucket_name=$1  # First argument: S3 bucket name
    local file_name=$2    # Second argument: Name of the file in the bucket
    local expiry=$3       # Third argument: Expiry time in seconds for the URL
    
    echo "Generating pre-signed URL..."
    # Generate a pre-signed URL that allows temporary access to the file
    presigned_url=$(aws s3 presign "s3://$bucket_name/$file_name" --expires-in "$expiry")
    
    echo "Pre-signed URL (valid for $expiry seconds):"
    echo "$presigned_url"
}

# Main script execution begins here

# Step 1: Ensure AWS CLI is installed
check_aws_cli

# Step 2: Configure AWS CLI with user credentials
configure_aws

# Step 3: Prompt the user for S3 bucket details
read -p "Enter S3 bucket name: " bucket_name  # Get bucket name from user
read -p "Enter AWS region (e.g., us-east-1): " region  # Get AWS region from user

# Step 4: Create the S3 bucket securely
create_s3_bucket "$bucket_name" "$region"

# Step 5: Prompt the user for the file to upload
read -p "Enter file path to upload: " file_path  # Get file path from user

# Step 6: Upload the specified file to the created S3 bucket
upload_file "$file_path" "$bucket_name"

# Step 7: Extract file name from file path
file_name=$(basename "$file_path")

# Step 8: Generate a pre-signed URL valid for 1 hour (3600 seconds)
generate_presigned_url "$bucket_name" "$file_name" 3600
