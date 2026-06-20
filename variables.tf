variable "environment" {
  description = "Logical environment name for the checkout messaging stack. The prod environment intentionally keeps the historic unprefixed queue names."
  type        = string
  default     = "prod"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,30}$", var.environment))
    error_message = "environment must be a lowercase name containing only letters, numbers, and hyphens, starting with a letter or number."
  }
}

variable "service_name" {
  description = "Owning service for the queues."
  type        = string
  default     = "checkout"

  validation {
    condition     = trimspace(var.service_name) != ""
    error_message = "service_name must not be empty."
  }
}

variable "cost_center" {
  description = "Cost center used for chargeback reporting on all queue resources."
  type        = string
  default     = "ecom-checkout"

  validation {
    condition     = trimspace(var.cost_center) != ""
    error_message = "cost_center must not be empty."
  }
}

variable "dlq_max_receive_count" {
  description = "Standard number of receives before a message is moved to the queue's own dead-letter queue. Applied consistently to every checkout queue."
  type        = number
  default     = 5

  validation {
    condition     = var.dlq_max_receive_count >= 1 && var.dlq_max_receive_count <= 1000 && floor(var.dlq_max_receive_count) == var.dlq_max_receive_count
    error_message = "dlq_max_receive_count must be an integer between 1 and 1000."
  }
}

variable "checkout_queues" {
  description = <<EOT
Map of checkout domain queues to create. Keys are stable logical queue IDs used
in state and outputs. By default, prod queue names are the historic unprefixed
names. Non-prod environments are prefixed with the environment unless an
explicit name override is supplied.
EOT
  type = map(object({
    name = optional(string)
  }))

  default = {
    "orders-created"      = {}
    "payments-captured"   = {}
    "inventory-reserved"  = {}
  }

  validation {
    condition = alltrue([
      for key, queue in var.checkout_queues :
      can(regex("^[A-Za-z0-9_-]{1,76}$", key)) &&
      !can(regex("-dlq$", key)) &&
      (queue.name == null ? true : can(regex("^[A-Za-z0-9_-]{1,80}$", queue.name)))
    ])
    error_message = "Each checkout_queues key must be a valid base SQS queue name of 1-76 characters and must not end in -dlq; explicit names must be valid SQS queue names of 1-80 characters."
  }
}

