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

echo "Setting up PhotoAtom Storage Secrets for MinIO..."
PHOTOATOM_CONSOLE_ACCESS_KEY="photoatom"
PHOTOATOM_CONSOLE_SECRET_KEY="$(openssl rand -base64 16)"

sed -i "s|PHOTOATOM_CONSOLE_ACCESS_KEY_HERE|$PHOTOATOM_CONSOLE_ACCESS_KEY|g" secrets
sed -i "s|PHOTOATOM_CONSOLE_ACCESS_KEY_HERE|$(echo $PHOTOATOM_CONSOLE_ACCESS_KEY | base64)|g" storage-user-secret.yml

sed -i "s|PHOTOATOM_CONSOLE_SECRET_KEY_HERE|$PHOTOATOM_CONSOLE_SECRET_KEY|g" secrets
sed -i "s|PHOTOATOM_CONSOLE_SECRET_KEY_HERE|$(echo $PHOTOATOM_CONSOLE_SECRET_KEY | base64)|g" storage-user-secret.yml

kubectl apply -f photoatom-user-secret.yml

echo "Setting up Postgres Storage Secrets for MinIO..."
POSTGRES_CONSOLE_ACCESS_KEY="postgres"
POSTGRES_CONSOLE_SECRET_KEY="$(openssl rand -base64 16)"

sed -i "s|POSTGRES_CONSOLE_ACCESS_KEY_HERE|$POSTGRES_CONSOLE_ACCESS_KEY|g" secrets
sed -i "s|POSTGRES_CONSOLE_ACCESS_KEY_HERE|$(echo $POSTGRES_CONSOLE_ACCESS_KEY | base64)|g" storage-user-secret.yml

sed -i "s|POSTGRES_CONSOLE_SECRET_KEY_HERE|$POSTGRES_CONSOLE_SECRET_KEY|g" secrets
sed -i "s|POSTGRES_CONSOLE_SECRET_KEY_HERE|$(echo $POSTGRES_CONSOLE_SECRET_KEY | base64)|g" storage-user-secret.yml

kubectl apply -f postgres-user-secret.yml

echo "Setting up MinIO Certificate CA and sleeping for 10 seconds..."
kubectl apply -f ca.yml
sleep 10

echo "Setting up MinIO Certificate CA Issuer and sleeping for 10 seconds..."
kubectl apply -f ca-issuer.yml
sleep 10

echo "Setting up MinIO Tenant Certificate and sleeping for 10 seconds..."
kubectl apply -f tenant-certificate.yml
sleep 10

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