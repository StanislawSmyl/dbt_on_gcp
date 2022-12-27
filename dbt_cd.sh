export BUCKET_NAME=$PROJECT_ID-dbt

cd /home/jaffle_shop

# Error out the whole script if one of the steps fail
set -e

# Save SA credentials to file to use them with dbt to auth against BigQuery
jq -n "$DBT_SA" > /tmp/credentials.json
export KEYFILE=/tmp/credentials.json

# Get previous manifest.json file from GCS
echo gs://$BUCKET_NAME/manifest.json
gsutil cp gs://$BUCKET_NAME/manifest.json /tmp/manifest.json

# Build models that were changed before the previous run
dbt run --profiles-dir . --select state:modified --state /tmp

# Run tests
dbt test --profiles-dir .

# Compile new manifest
dbt compile --profiles-dir .

# Move new manifest to GCS
gsutil cp target/manifest.json gs://$BUCKET_NAME/manifest.json
