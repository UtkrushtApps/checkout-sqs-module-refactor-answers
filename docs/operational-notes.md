# Checkout Messaging — Operational Notes

## Environments
- `prod` is the only workspace with live traffic today; `staging` is provisioned occasionally for load tests.
- The live production queue names are unprefixed: `orders-created`, `payments-captured`, `inventory-reserved`, each with a `-dlq` counterpart.
- This configuration intentionally preserves the unprefixed names when `var.environment == "prod"`. Non-production environments are prefixed with the environment name unless a queue name override is supplied.

## Safety expectations
- SQS queues in `prod` hold in-flight checkout events. Replacing a queue (destroy + create) loses those messages and breaks the checkout flow.
- Any change whose plan shows a queue being destroyed or replaced must be reviewed by a senior engineer before apply. The goal for routine refactors is a clean plan with no destroys or replacements.
- The checkout queue module uses one input map and a single `max_receive_count` value so every queue redrives to its own DLQ with the same retry threshold.
- Every primary queue and DLQ must carry `Service`, `Environment`, and `CostCenter` tags. The module validates that these common tags are present and applies them uniformly.

## State-safe refactor / migration note

The root resources were refactored into `module.checkout_queues`. The queue names themselves are unchanged in `prod`; only the Terraform addresses changed. Terraform 1.5+ will process the checked-in `moved` blocks in `main.tf` and should report address moves like:

- `aws_sqs_queue.orders_created` -> `module.checkout_queues.aws_sqs_queue.main["orders-created"]`
- `aws_sqs_queue.orders_created_dlq` -> `module.checkout_queues.aws_sqs_queue.dlq["orders-created"]`
- `aws_sqs_queue.payments_captured` -> `module.checkout_queues.aws_sqs_queue.main["payments-captured"]`
- `aws_sqs_queue.payments_captured_dlq` -> `module.checkout_queues.aws_sqs_queue.dlq["payments-captured"]`
- `aws_sqs_queue.inventory_reserved` -> `module.checkout_queues.aws_sqs_queue.main["inventory-reserved"]`
- `aws_sqs_queue.inventory_reserved_dlq` -> `module.checkout_queues.aws_sqs_queue.dlq["inventory-reserved"]`

Before any real production apply:

1. Select the `prod` workspace and confirm `var.environment` is `prod`.
2. Run `terraform plan` against the locked production backend.
3. Confirm the plan has **no destroys and no replacements** for any `aws_sqs_queue` resource. Updates to tags/redrive policy are expected; queue name changes are not.
4. If the production state does not include the old root addresses, import the existing queues into the module addresses instead of creating replacements. For the AWS provider, import SQS queues by URL, for example: `terraform import 'module.checkout_queues.aws_sqs_queue.main["orders-created"]' 'https://sqs.us-east-1.amazonaws.com/<account-id>/orders-created'` and repeat for each DLQ using its module address.
5. Do not apply if the plan proposes deleting, replacing, or renaming a live production queue.

## Standards
- Every queue and dead-letter queue must carry `Service`, `Environment`, and `CostCenter` tags. `CostCenter` feeds chargeback reporting and was previously inconsistent.
- Dead-letter handling is uniform: each queue redrives to its own dead-letter queue with the agreed retry threshold from `var.dlq_max_receive_count`.

## Collaboration
- Other teams add new event queues to this stack. A new queue should be addable by editing the `checkout_queues` map rather than copying resource blocks.
- Document any state moves, imports, or migration steps in the PR description so reviewers can confirm safety before a real apply.

