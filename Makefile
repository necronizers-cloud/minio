deploy: base_setup
	@echo "Deployment for MinIO Tenant"
	@cd src && ./automate.sh
base_setup:
	@echo "Base Setup for MinIO Deployment"
	@cd base && ./automate.sh