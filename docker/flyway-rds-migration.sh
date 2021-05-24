#!/usr/bin/env bash

# Optional Branch argument that can be specified by Fargate Task Definition
github_branch="${1:-master}"

echo "Starting Fargate task to run flyway migration from ${github_branch} for RDS database ${DB_NAME} in AWS Region ${REGION}"

# Get Repositroy Deploy Key to pull SQL code from GitHub
mkdir ~/.ssh
aws secretsmanager get-secret-value \
  --secret-id "${REPOSITORY_DEPLOY_KEY_SECRET}" \
  --region "${REGION}" \
  --query SecretString \
  --output text \
> ~/.ssh/id_rsa
chmod 0600 ~/.ssh/id_rsa
ssh-keyscan github.com >> ~/.ssh/known_hosts

# Clone GitHub branch to get access to SQL migrations
git clone --single-branch -b "${github_branch}" "git@github.com:${REPOSITORY_OWNER}/${REPOSITORY_PATH}.git"
cd "${REPOSITORY_PATH}"

# Get DB user Passwords
# Change the secret-ids here to match the ones you created in the previous section
sqladmin_password=$(
  aws secretsmanager get-secret-value \
    --secret-id postgresql@aurora-serverless-flyway-db@sqladmin \
    --region "${REGION}" \
    --query SecretString \
    --output text \
  | jq -r '.password'
)
read_only_password=$(
  aws secretsmanager get-secret-value \
    --secret-id postgresql@aurora-serverless-flyway-db@read_only \
    --region "${REGION}" \
    --query SecretString \
    --output text \
  | jq -r '.password'
)
sample_application_password=$(
  aws secretsmanager get-secret-value \
    --secret-id postgresql@aurora-serverless-flyway-db@sample_application \
    --region "${REGION}" \
    --query SecretString \
    --output text \
  | jq -r '.password'
)

# Set flyway config options
flyway_options=(
  "-url=jdbc:postgresql://${DB_HOST}:5432/${DB_NAME}"
  "-user=sqladmin"
  "-password=${sqladmin_password}"
  "-locations=filesystem:./sql"
  "-placeholders.DATABASE_NAME=${DB_NAME}"
  "-placeholders.READ_ONLY_PASSWORD=${read_only_password}"
  "-placeholders.SAMPLE_APPLICATION_PASSWORD=${sample_application_password}"
)

# Run flyway migration. Display schema version details before and after migration.
/flyway/flyway "${flyway_options[@]}" info
/flyway/flyway "${flyway_options[@]}" migrate
/flyway/flyway "${flyway_options[@]}" info
