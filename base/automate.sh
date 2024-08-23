#!/bin/bash -e

echo "Setting up Self Signed Cluster Issuer..."
kubectl apply -f cluster-issuer.yml

echo "Setting up CA Certificate to be used with the MinIO Operator..."
kubectl apply -f minio-ca.yml

echo "Setting up Issuer for the MinIO Operator Namespace..."
kubectl apply -f minio-issuer.yml

echo "Setting up MinIO STS Certificate..."
kubectl apply -f sts-cert.yml

echo "Restarting the MinIO Operator..."
kubectl rollout restart deployments.apps/minio-operator -n minio-operator