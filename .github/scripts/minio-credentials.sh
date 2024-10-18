#!/bin/bash -e

function setup_mc {

  echo "Setting up MinIO CLI credentials..."

  # Fetch MinIO Configuration Secret from Kubernetes
  MINIO_CONFIGURATION_DOCUMENT=$(kubectl get secret minio-storage-configuration -n minio --output=jsonpath='{.data}' | jq -rc '."config.env"' | base64 -d)

  # Extract root username and password for MinIO
  MINIO_ROOT_USER=$(echo "$MINIO_CONFIGURATION_DOCUMENT" | grep MINIO_ROOT_USER | cut -d= -f2 | sed 's|"||g')
  MINIO_ROOT_PASSWORD=$(echo "$MINIO_CONFIGURATION_DOCUMENT" | grep MINIO_ROOT_PASSWORD | cut -d= -f2 | sed 's|"||g')

  # Setup aliasing in the MinIO CLI
  mc alias set photoatom https://localhost:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" --insecure

  echo "MinIO CLI Credentials has been setup"

}

function save_credentials_to_minio {

  KUBE_SECRET_NAMES=$1

  echo "Generating credentials for: $KUBE_SECRET_NAMES"

  # Looping over list of Kubernetes Credentials
  for SECRET in $KUBE_SECRET_NAMES
  do
    echo "Executing script for: $SECRET"

    # Fetching Kubernetes Secret document
    SECRET_DOCUMENT=$(kubectl get secret -n minio $SECRET --output jsonpath='{.data}')

    # Fetching credentials for the service account to be generated
    USER=$(echo $SECRET_DOCUMENT | jq -rc '.MINIO_USER' | base64 -d)
    ACCESS_KEY=$(echo $SECRET_DOCUMENT | jq -rc '.MINIO_ACCESS_KEY' | base64 -d)
    ACCESS_SECRET=$(echo $SECRET_DOCUMENT | jq -rc '.MINIO_ACCESS_SECRET' | base64 -d)

    echo "Checking if service account: $ACCESS_KEY exists for $USER"

    # Checking if service account already exists or not.
    CHECK_ACCESS_KEY=$(mc admin user svcacct list photoatom "$USER" --insecure | grep -c "$ACCESS_KEY" || true)

    if [[ "$CHECK_ACCESS_KEY" == "0" ]]
    then
      echo "Service account: $ACCESS_KEY does not exists for $USER, creating..."

      # Create Service Account for the user.
      mc admin user svcacct add \
        --access-key "$ACCESS_KEY" \
        --secret-key "$ACCESS_SECRET" \
        photoatom "$USER" \
        --insecure

       echo "Service account: $ACCESS_KEY created for $USER"
    else
      echo "Service account: $ACCESS_KEY exists for $USER"
    fi
  done

}

# Sleep till Tenant is ready for connections
echo "Sleeping till Tenant is ready for connections..."
sleep 60

# Setup port forwarding for MinIO
echo "Setting up port forwarding for MinIO..."

kubectl port-forward svc/minio-hl 9000 -n minio > /dev/null &
sleep 3
PROCESS_NUMBER=$(ps | grep kubectl | xargs | cut -f1 -d" ")

echo "Port forwarding for MinIO has been setup"

# Setup MinIO CLI credentials
setup_mc

# Generate and save credentials to MinIO
save_credentials_to_minio "postgres-access-key"

# Kill port forwarding
kill -9 "$PROCESS_NUMBER"