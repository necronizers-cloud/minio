#!/bin/bash -e

echo "Setting up Self Signed Cluster Issuer and sleeping for 10 seconds..."
kubectl apply -f cluster-issuer.yml
sleep 10

echo "Setting up CA Certificate to be used with the MinIO Operator and sleeping for 10 seconds..."
kubectl apply -f minio-ca.yml
sleep 10

echo "Setting up Issuer for the MinIO Operator Namespace and sleeping for 10 seconds..."
kubectl apply -f minio-issuer.yml
sleep 10

echo "Setting up MinIO STS Certificate and sleeping for 10 seconds..."
kubectl apply -f sts-cert.yml
sleep 10

echo "Restarting the MinIO Operator..."
kubectl rollout restart deployments.apps/minio-operator -n minio-operator