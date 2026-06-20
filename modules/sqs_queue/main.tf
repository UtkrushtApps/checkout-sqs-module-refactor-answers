# Reusable checkout SQS module. It manages a map of primary queues, each with
# its own dead-letter queue, consistent redrive policy, and required tags.

locals {
  queue_definitions = {
    for key, queue in var.queues : key => {
      name     = queue.name
      dlq_name = coalesce(queue.dlq_name, "${queue.name}-dlq")
      tags     = merge(queue.tags, var.common_tags)
    }
  }
}

resource "aws_sqs_queue" "dlq" {
  for_each = local.queue_definitions

  name = each.value.dlq_name

  tags = each.value.tags
}

resource "aws_sqs_queue" "main" {
  for_each = local.queue_definitions

  name = each.value.name

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[each.key].arn
    maxReceiveCount     = var.max_receive_count
  })

  tags = each.value.tags
}

