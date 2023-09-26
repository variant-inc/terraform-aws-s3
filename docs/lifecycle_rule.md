# Lifecycle Rules

Controlling bucket lifecycle rules, zero or more supported.
Each rule object has to have at least one of actions specified, others can be ommited:

- `expiration`
- `abort_incomplete_multipart_upload_days`
- `transition_storage_class`
- `noncurrent_version_transition`
- `noncurrent_version_expiration_days`

Storage classes for transition:

- `STANDARD`
- `REDUCED_REDUNDANCY`
- `ONEZONE_IA`
- `INTELLIGENT_TIERING`
- `GLACIER`
- `DEEP_ARCHIVE`
- `STANDARD_IA`.

<!-- markdownlint-disable line-length-->
```json
"lifecycle_rule": [{
  "prefix": "<prefix on which to apply rule>",
  "enabled": <true or false>,
  "abort_incomplete_multipart_upload_days": <days for deletion of failed multipart uploads, minimum 1>,
  "expiration": [{
    "days": <days for current version expiration>,
    "expired_object_delete_marker": <true or false>
  }],
  "transition_storage_class": [{
    "days": <days for current version transition>,
    "storage_class": "<storage class for current version transition>"
  }],
  "noncurrent_version_transition": [{
    "days": <days for noncurrent version transition>,
    "storage_class": "<storage class for noncurrent version transition>"
  }],
  "noncurrent_version_expiration_days": <days for noncurrent version expiration>
}]
```
