###############################################################################
# State Bucket Tests
###############################################################################

variables {
  region         = "ap-southeast-2"
  aws_account_id = "123456789012"
}

run "bucket_name_includes_account_id" {
  command = plan

  # Bucket name is derived from aws_account_id so it is globally unique per
  # account and clearly identifies who owns the state file.
  assert {
    condition     = aws_s3_bucket.state.bucket == "${var.aws_account_id}-bucket-state-file-karpenter"
    error_message = "Bucket name must be '<account_id>-bucket-state-file-karpenter'"
  }
}

run "bucket_name_follows_convention" {
  command = plan

  assert {
    condition     = can(regex("^[0-9]{12}-bucket-state-file-karpenter$", aws_s3_bucket.state.bucket))
    error_message = "Bucket name must match the pattern '<12-digit-account-id>-bucket-state-file-karpenter'"
  }
}

run "force_destroy_enabled" {
  command = plan

  # force_destroy = true allows clean teardown of the demo environment.
  # In production this should be false to prevent accidental state loss.
  assert {
    condition     = aws_s3_bucket.state.force_destroy == true
    error_message = "force_destroy must be true for the demo state bucket to allow clean teardown"
  }
}

run "output_bucket_id_set" {
  command = plan

  assert {
    condition     = output.state_bucket_id != ""
    error_message = "state_bucket_id output must be populated"
  }
}

run "output_bucket_region_set" {
  command = plan

  assert {
    condition     = output.state_bucket_region != ""
    error_message = "state_bucket_region output must be populated"
  }
}

run "account_id_flows_into_bucket_name" {
  command = plan

  variables {
    aws_account_id = "999888777666"
  }

  assert {
    condition     = aws_s3_bucket.state.bucket == "999888777666-bucket-state-file-karpenter"
    error_message = "Changing aws_account_id must update the bucket name accordingly"
  }
}
