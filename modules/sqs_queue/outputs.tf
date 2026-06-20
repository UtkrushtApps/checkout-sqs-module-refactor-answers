output "queue_endpoints" {
  description = "Map of queue logical IDs to primary queue URL/ARN and DLQ metadata."
  value = {
    for key, queue in aws_sqs_queue.main : key => {
      name = queue.name
      url  = queue.url
      arn  = queue.arn

      dlq = {
        name = aws_sqs_queue.dlq[key].name
        url  = aws_sqs_queue.dlq[key].url
        arn  = aws_sqs_queue.dlq[key].arn
      }
    }
  }
}

output "queue_urls" {
  description = "Map of queue logical IDs to primary queue URLs."
  value = {
    for key, queue in aws_sqs_queue.main : key => queue.url
  }
}

output "queue_arns" {
  description = "Map of queue logical IDs to primary queue ARNs."
  value = {
    for key, queue in aws_sqs_queue.main : key => queue.arn
  }
}

output "dlq_arns" {
  description = "Map of queue logical IDs to dead-letter queue ARNs."
  value = {
    for key, queue in aws_sqs_queue.dlq : key => queue.arn
  }
}

