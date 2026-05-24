## ADDED Requirements

### Requirement: Terraform State Management
The system SHALL use a Google Cloud Storage (GCS) bucket as a remote backend to store the Terraform state file securely.

#### Scenario: Remote State Initialization
- **WHEN** `terraform init` is run in the terraform directory
- **THEN** the system connects to the specified GCS bucket and retrieves or creates the state file

### Requirement: Firebase Resource Management
The system SHALL use Terraform to manage Firebase resources, including the Android App, Web App, and Firestore configuration within the `roombooker-5e947` project.

#### Scenario: Infrastructure Synchronization
- **WHEN** `terraform apply` is executed
- **THEN** the infrastructure state in GCP/Firebase is updated to match the Terraform configuration

### Requirement: Service Account Automation
The system SHALL create and manage a dedicated service account with the necessary permissions for GitHub Actions to deploy to Firebase.

#### Scenario: Deployment Credential Generation
- **WHEN** Terraform is applied
- **THEN** a service account key is generated that can be used by the CI/CD pipeline
