variable "queues" {
  description = <<EOT
Map of queue definitions. The map key is a stable logical identifier used in
Terraform state and outputs. Each value supplies the concrete primary queue
name; the DLQ name defaults to "<name>-dlq" unless explicitly overridden.
EOT
  type = map(object({
    name     = string
    dlq_name = optional(string)
    tags     = optional(map(string), {})
  }))

  validation {
    condition = length(var.queues) > 0
    error_message = "At least one queue must be defined."
  }

  validation {
    condition = alltrue([
      for key, queue in var.queues :
      can(regex("^[A-Za-z0-9_-]{1,80}$", queue.name)) &&
      can(regex("^[A-Za-z0-9_-]{1,80}$", coalesce(queue.dlq_name, "${queue.name}-dlq"))) &&
      key != ""
    ])
    error_message = "Every queue and DLQ name must be a valid SQS queue name containing 1-80 letters, numbers, underscores, or hyphens; map keys must not be empty."
  }
}

variable "max_receive_count" {
  description = "Standard number of receives before a message is moved to its queue's dead-letter queue."
  type        = number
  default     = 5

  validation {
    condition     = var.max_receive_count >= 1 && var.max_receive_count <= 1000 && floor(var.max_receive_count) == var.max_receive_count
    error_message = "max_receive_count must be an integer between 1 and 1000."
  }
}

variable "common_tags" {
  description = "Required tags applied to every primary queue and DLQ. Must include Service, Environment, and CostCenter."
  type        = map(string)

  validation {
    condition = length(setsubtract(toset(["Service", "Environment", "CostCenter"]), toset(keys(var.common_tags)))) == 0 && alltrue([
      for required_key in ["Service", "Environment", "CostCenter"] : trimspace(lookup(var.common_tags, required_key, "")) != ""
    ])
    error_message = "common_tags must include non-empty Service, Environment, and CostCenter values."
  }
}

