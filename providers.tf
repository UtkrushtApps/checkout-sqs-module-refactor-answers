# Provider is pointed at the local LocalStack emulator so no real cloud
# credentials are required. Endpoints and dummy credentials are safe for
# local emulation only.
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    sqs = "http://127.0.0.1:4566"
    sts = "http://127.0.0.1:4566"
  }
}

