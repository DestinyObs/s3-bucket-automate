#!/bin/bash

# Function to check if AWS CLI is installed and install it if necessary
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        echo "AWS CLI not found. Installing AWS CLI..."
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install
        rm -rf aws awscliv2.zip
        echo "AWS CLI installed successfully."
    else
        echo "AWS CLI is already installed."
    fi
}

# Function to configure AWS CLI
configure_aws() {
    echo "Configuring AWS CLI..."
    aws configure
}

# Function to create an S3 bucket securely
create_s3_bucket() {
    local bucket_name=$1
    local region=$2

    echo "Creating S3 bucket: $bucket_name in region: $region..."
    aws s3api create-bucket --bucket "$bucket_name" --region "$region"

    if [ $? -eq 0 ]; then
        echo "Bucket created successfully: $bucket_name"
    else
        echo "Failed to create bucket."
        exit 1
    fi

    # Apply security settings
    aws s3api put-public-access-block --bucket "$bucket_name" --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
    echo "Bucket secured: Public access blocked."
}

# Function to upload a file
upload_file() {
    local file_path=$1
    local bucket_name=$2

    echo "Uploading file: $file_path to S3 bucket: $bucket_name..."
    aws s3 cp "$file_path" "s3://$bucket_name/"
    
    if [ $? -eq 0 ]; then
        echo "File uploaded successfully."
    else
        echo "File upload failed."
        exit 1
    fi
}

# Function to generate a pre-signed URL
generate_presigned_url() {
    local bucket_name=$1
    local file_name=$2
    local expiry=$3

    echo "Generating pre-signed URL..."
    presigned_url=$(aws s3 presign "s3://$bucket_name/$file_name" --expires-in "$expiry")
    echo "Pre-signed URL (valid for $expiry seconds):"
    echo "$presigned_url"
}

# Main script execution
check_aws_cli
configure_aws

read -p "Enter S3 bucket name: " bucket_name
read -p "Enter AWS region (e.g., us-east-1): " region
create_s3_bucket "$bucket_name" "$region"

read -p "Enter file path to upload: " file_path
upload_file "$file_path" "$bucket_name"

file_name=$(basename "$file_path")
generate_presigned_url "$bucket_name" "$file_name" 3600
