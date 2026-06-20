locals {
  environment = var.environment

  # Common tags are applied by the reusable module to every primary queue and
  # every dead-letter queue. CostCenter is intentionally required and uniform.
  common_tags = {
    Service     = var.service_name
    Environment = local.environment
    CostCenter  = var.cost_center
  }

  # Production already has live, unprefixed queues. Keep those identities
  # stable. Other environments may use an environment prefix to avoid name
  # collisions in shared accounts.
  queue_name_prefix = local.environment == "prod" ? "" : "${local.environment}-"

  checkout_queue_configs = {
    for queue_key, queue in var.checkout_queues : queue_key => {
      name = coalesce(queue.name, "${local.queue_name_prefix}${queue_key}")
    }
  }
}

