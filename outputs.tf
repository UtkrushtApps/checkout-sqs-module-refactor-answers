# The checkout deployment module consumes this typed map to configure event
# publishing. Keys match var.checkout_queues.
output "checkout_queue_endpoints" {
  description = "Map of checkout queue logical IDs to primary queue URL/ARN and DLQ metadata."
  value       = module.checkout_queues.queue_endpoints
}

output "checkout_queue_urls" {
  description = "Map of checkout queue logical IDs to primary queue URLs."
  value       = module.checkout_queues.queue_urls
}

output "checkout_queue_arns" {
  description = "Map of checkout queue logical IDs to primary queue ARNs."
  value       = module.checkout_queues.queue_arns
}

# Backward-compatible outputs for existing consumers while they migrate to
# checkout_queue_endpoints.
output "orders_created_queue_url" {
  description = "URL of the orders-created queue."
  value       = module.checkout_queues.queue_endpoints["orders-created"].url
}

output "payments_captured_queue_arn" {
  description = "ARN of the payments-captured queue."
  value       = module.checkout_queues.queue_endpoints["payments-captured"].arn
}

