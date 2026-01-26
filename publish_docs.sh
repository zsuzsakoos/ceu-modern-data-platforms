#!/bin/bash
set -e

# Disable AWS CLI pagination
export AWS_PAGER=""

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DBT_PROJECT_DIR="$SCRIPT_DIR/airbnb"

# Check if bucket name is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <bucket-name>"
    echo "Example: $0 my-dbt-docs-bucket"
    exit 1
fi

BUCKET_NAME="$1"
REGION="${AWS_REGION:-eu-west-1}"

echo "=== dbt Docs Publisher ==="
echo "Bucket: $BUCKET_NAME"
echo "Region: $REGION"
echo "dbt Project: $DBT_PROJECT_DIR"
echo ""

# Step 1: Generate dbt docs
echo ">>> Generating dbt docs..."
cd "$DBT_PROJECT_DIR"
dbt docs generate
echo "dbt docs generated successfully."
echo ""

# Step 2: Create bucket if it doesn't exist
echo ">>> Checking if bucket exists..."
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "Bucket '$BUCKET_NAME' already exists."
else
    echo "Creating bucket '$BUCKET_NAME'..."
    if [ "$REGION" = "us-east-1" ]; then
        aws s3api create-bucket --bucket "$BUCKET_NAME"
    else
        aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION" \
            --create-bucket-configuration LocationConstraint="$REGION"
    fi
    echo "Bucket created."
fi
echo ""

# Step 3: Disable block public access
echo ">>> Disabling block public access..."
aws s3api put-public-access-block --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
    "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"
echo "Public access block disabled."
echo ""

# Step 4: Set bucket policy for public read access
echo ">>> Setting bucket policy for public access..."
BUCKET_POLICY=$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${BUCKET_NAME}/*"
        }
    ]
}
EOF
)
echo "$BUCKET_POLICY" | aws s3api put-bucket-policy --bucket "$BUCKET_NAME" --policy file:///dev/stdin
echo "Bucket policy set."
echo ""

# Step 5: Enable static website hosting
echo ">>> Enabling static website hosting..."
aws s3 website "s3://$BUCKET_NAME" --index-document index.html --error-document index.html
echo "Static website hosting enabled."
echo ""

# Step 6: Upload dbt docs (target folder contents)
echo ">>> Uploading dbt docs to S3..."
aws s3 sync "$DBT_PROJECT_DIR/target" "s3://$BUCKET_NAME" \
    --delete \
    --content-type "text/html" \
    --exclude "*" \
    --include "*.html"

aws s3 sync "$DBT_PROJECT_DIR/target" "s3://$BUCKET_NAME" \
    --delete \
    --exclude "*.html"
echo "Upload complete."
echo ""

# Step 7: Construct website URL
if [ "$REGION" = "us-east-1" ]; then
    WEBSITE_URL="http://${BUCKET_NAME}.s3-website-${REGION}.amazonaws.com"
else
    WEBSITE_URL="http://${BUCKET_NAME}.s3-website.${REGION}.amazonaws.com"
fi

# Step 8: Verify website is accessible (with retries)
echo ">>> Verifying website accessibility..."
MAX_RETRIES=5
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$WEBSITE_URL" || echo "000")
    if [ "$HTTP_STATUS" = "200" ]; then
        echo "Website is accessible! (HTTP $HTTP_STATUS)"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            echo "Website not ready yet (HTTP $HTTP_STATUS). Retrying in 3 seconds... ($RETRY_COUNT/$MAX_RETRIES)"
            sleep 3
        else
            echo "Warning: Website returned HTTP $HTTP_STATUS after $MAX_RETRIES attempts."
            echo "It may take a few more moments to become available."
        fi
    fi
done
echo ""

# Step 9: Print the website URL
echo "=========================================="
echo "dbt Documentation Published Successfully!"
echo "=========================================="
echo ""
echo "Website URL: $WEBSITE_URL"
echo ""
