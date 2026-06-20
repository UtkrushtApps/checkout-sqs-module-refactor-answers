# Solution Steps

1. Replace the copy-pasted root `aws_sqs_queue` resources with a single `module "checkout_queues"` call driven by a map of queue definitions.

2. Preserve production queue identity by computing unprefixed queue names when `var.environment == "prod"`; only prefix names for non-production environments unless an explicit queue name is supplied.

3. Refactor `modules/sqs_queue` from a single-queue module into a map-driven module that creates `aws_sqs_queue.dlq` and `aws_sqs_queue.main` with `for_each`.

4. Use one shared `max_receive_count` input so all checkout queues redrive consistently, and wire every primary queue to its own DLQ by referencing `aws_sqs_queue.dlq[each.key].arn`.

5. Validate inputs: queue names must be valid SQS names, retry count must be a positive integer, and required common tags must include non-empty `Service`, `Environment`, and `CostCenter`.

6. Merge tags inside the module so required common tags are applied to both the primary queue and DLQ for every queue.

7. Add Terraform `moved` blocks mapping each old root resource address to its new module resource address, preventing Terraform from treating the refactor as destroy/create churn in existing state.

8. Expose module outputs as maps containing each queue’s URL and ARN, plus DLQ metadata, and keep existing legacy outputs for backward compatibility.

9. Update operational documentation with the production migration note: select prod, verify the plan has no queue destroys/replacements, rely on moved blocks when old state addresses exist, and import existing queues into module addresses if state is missing.

10. Run `terraform fmt`, `terraform init -backend=false`, and `terraform validate`; for production, inspect `terraform plan` and do not apply if any live queue is proposed for replacement or destruction.

