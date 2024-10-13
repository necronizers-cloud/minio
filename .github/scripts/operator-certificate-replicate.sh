#!/bin/bash -e

# Check if certs are required to be replicated
CHECK_TENANT_CERT=$(kubectl get secrets -n minio-operator | grep -c "operator-ca-tls-photoatom-object-storage" || true)

if [[ "$CHECK_TENANT_CERT" == "0" ]]
then

  # Sleep for some time to give time for certs creation
  echo "Sleeping for 30 seconds to give time for certificates creation"
  sleep 30

  # Replicate certificates from MinIO Namespace to Operator Namespace
  echo "Replicating certificates from MinIO Namespace to Operator Namespace if it does not exist"
  kubectl get secrets -n minio minio-tls -o=json | jq -rc '.data."ca.crt"' | base64 -d > ca.crt
  kubectl create secret generic operator-ca-tls-photoatom-object-storage --from-file=ca.crt -n minio-operator

  # Restart MinIO Operator Deployment
  kubectl rollout restart deployments.apps/minio-operator -n minio-operator
  kubectl rollout status deployments.apps/minio-operator -n minio-operator

else
  echo "Certificates already replicated, skipping ahead..."
fi