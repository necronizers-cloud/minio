#!/bin/bash -e

echo "Setting up secrets file to store data on deployment..."
cp ../secrets.example ./secrets

echo "Setting up namespace for MinIO Deployment..."
kubectl apply -f namespace.yml

echo "Setting up Storage Secrets for MinIO..."
CONFIG_MINIO_ROOT_USER="minio_user"
CONFIG_MINIO_ROOT_PASSWORD="$(openssl rand -base64 16)"

sed -i "s|CONFIG_MINIO_ROOT_USER|$CONFIG_MINIO_ROOT_USER|g" secrets
sed -i "s|CONFIG_MINIO_ROOT_USER|$CONFIG_MINIO_ROOT_USER|g" storage-config-secret.yml

sed -i "s|CONFIG_MINIO_ROOT_PASSWORD|$CONFIG_MINIO_ROOT_PASSWORD|g" secrets
sed -i "s|CONFIG_MINIO_ROOT_PASSWORD|$CONFIG_MINIO_ROOT_PASSWORD|g" storage-config-secret.yml

kubectl apply -f storage-config-secret.yml

echo "Setting up Storage User Secrets for MinIO..."
CONFIG_CONSOLE_ACCESS_KEY="console_user"
CONFIG_CONSOLE_SECRET_KEY="$(openssl rand -base64 16)"

sed -i "s|CONFIG_CONSOLE_ACCESS_KEY|$CONFIG_CONSOLE_ACCESS_KEY|g" secrets
sed -i "s|CONFIG_CONSOLE_ACCESS_KEY|$(echo $CONFIG_CONSOLE_ACCESS_KEY | base64)|g" storage-user-secret.yml

sed -i "s|CONFIG_CONSOLE_SECRET_KEY|$CONFIG_CONSOLE_SECRET_KEY|g" secrets
sed -i "s|CONFIG_CONSOLE_SECRET_KEY|$(echo $CONFIG_CONSOLE_SECRET_KEY | base64)|g" storage-user-secret.yml

kubectl apply -f storage-user-secret.yml

echo "Setting up MinIO Certificate CA.."
kubectl apply -f ca.yml

echo "Setting up MinIO Certificate CA Issuer..."
kubectl apply -f ca-issuer.yml

echo "Setting up MinIO Tenant Certificate..."
kubectl apply -f tenant-certificate.yml

echo "Setting up MinIO Role..."
kubectl apply -f role.yml

echo "Setting up MinIO Service Account..."
kubectl apply -f service-account.yml

echo "Setting up MinIO Service Account Role Binding..."
kubectl apply -f role-binding.yml

echo "Setting up MinIO Tenant..."
kubectl apply -f tenant.yml

echo "Adding trust for the certificate..."
kubectl get secrets -n photoatom-object-storage minio-tls -o=jsonpath='{.data.ca\.crt}' | base64 -d > ca.crt
kubectl create secret generic operator-ca-tls-photoatom-object-storage --from-file=ca.crt -n minio-operator
kubectl rollout restart deployments.apps/minio-operator -n minio-operator
rm ca.crt

echo "Setting up Ingress for Console Access"
kubectl apply -f ingress.yml