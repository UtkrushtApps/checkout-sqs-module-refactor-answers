# Checkout messaging infrastructure for the ShopNest checkout service.
#
# Existing production queue names are already live and must remain stable:
#   orders-created / orders-created-dlq
#   payments-captured / payments-captured-dlq
#   inventory-reserved / inventory-reserved-dlq
#
# The reusable module below creates each primary queue and its own DLQ from a
# single typed input map. In prod, the computed names deliberately remain
# unprefixed to avoid replacing in-flight production queues.

module "checkout_queues" {
  source = "./modules/sqs_queue"

  queues            = local.checkout_queue_configs
  max_receive_count = var.dlq_max_receive_count
  common_tags       = local.common_tags
}

# State-safe refactor moves from the previous copy-pasted root resources into
# the reusable module. These moved blocks preserve Terraform ownership of the
# existing prod queues and prevent destroy/create churn caused only by address
# changes during the refactor.
moved {
  from = aws_sqs_queue.orders_created_dlq
  to   = module.checkout_queues.aws_sqs_queue.dlq["orders-created"]
}

moved {
  from = aws_sqs_queue.orders_created
  to   = module.checkout_queues.aws_sqs_queue.main["orders-created"]
}

moved {
  from = aws_sqs_queue.payments_captured_dlq
  to   = module.checkout_queues.aws_sqs_queue.dlq["payments-captured"]
}

moved {
  from = aws_sqs_queue.payments_captured
  to   = module.checkout_queues.aws_sqs_queue.main["payments-captured"]
}

moved {
  from = aws_sqs_queue.inventory_reserved_dlq
  to   = module.checkout_queues.aws_sqs_queue.dlq["inventory-reserved"]
}

moved {
  from = aws_sqs_queue.inventory_reserved
  to   = module.checkout_queues.aws_sqs_queue.main["inventory-reserved"]
}

