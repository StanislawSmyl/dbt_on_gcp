export PROJECT_ID="dbt-on-gcp"
export LOCATION="us-central1"
export BUCKET_NAME=$PROJECT_ID-dbt
# Project number can be found in response from `gcloud projects describe $PROJECT_ID`
export PROJECT_NR=147995594777
# tmp Location for Service Account JSON key file
export SA_KEY_FILE="/tmp/dbt_sa.json"
export BUILD_CONFIG_FILE="build_dbt_image.yaml"
export REPO_NAME="dbt_on_gcp"
export REPO_OWNER="StanislawSmyl"

# Initialize dbt environment
dbt init

# Create Service Account for running dbt workflows
export SA_NAME="dbt-sa"

# Create Service Account
gcloud iam service-accounts create $SA_NAME \
    --description="Service Account intended to be used by dbt tool" \
    --display-name=$SA_NAME

# Add BigQuery Admin role
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/bigquery.admin"

# Create Service Account key
gcloud iam service-accounts keys create $SA_KEY_FILE \
    --iam-account=$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com

# Enable Secret Manager API

export SECRET_NAME="dbt-sa"
# Create Secret
gcloud secrets create $SECRET_NAME \
    --replication-policy="automatic"

# Add first version of secret: content of dbt Service Account JSON key
gcloud secrets versions add $SECRET_NAME --data-file="$SA_KEY_FILE"

# Add permission for Cloud Build SA to access this Secret
gcloud secrets add-iam-policy-binding projects/$PROJECT_ID/secrets/$SECRET_NAME \
  --member serviceAccount:$PROJECT_NR@cloudbuild.gserviceaccount.com \
  --role roles/secretmanager.secretAccessor


# Create bucket with versioning enabled
gcloud storage buckets create gs://$BUCKET_NAME --location $LOCATION

# Add object versioning support
gcloud storage buckets update gs://$BUCKET_NAME --versioning

# Add empty manifest file so CD works
gsutil cp target/manifest.json gs://$BUCKET_NAME

# Create new Artifact Registry repository called "docker"
export REPOSITORY="docker"

gcloud artifacts repositories create $REPOSITORY \
    --repository-format=Docker \
    --location=$LOCATION \
    --description="Repository for keeping Docker images"

# Before, need to connect Github repository using UI
# https://cloud.google.com/build/docs/automating-builds/github/connect-repo-github
# Create Cloud Build trigger
gcloud beta builds triggers create github \
    --name="dbt-run" \
    --included-files="jaffle_shop/*" \
    --repo-name=$REPO_NAME \
    --repo-owner=$REPO_OWNER \
    --branch-pattern="^main$" \
    --build-config=$BUILD_CONFIG_FILE \
    --include-logs-with-status
