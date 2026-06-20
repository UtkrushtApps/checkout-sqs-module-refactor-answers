# Backend is intentionally left as local for the sandbox. In production this
# stack uses a remote backend with state locking. For this exercise the
# focus is on safe refactoring of the queue resources, not backend wiring.
#
# terraform {
#   backend "s3" {
#     bucket = "shopnest-tfstate"
#     key    = "checkout/messaging/terraform.tfstate"
#     region = "us-east-1"
#   }
# }

