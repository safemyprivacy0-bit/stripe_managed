# Changelog

## 0.2.0

### Fixed

- POST requests now send an `Idempotency-Key` header. Transient failures are
  retried automatically, and without a key a retried POST could create a
  duplicate refund or checkout session. The key is generated per call; pass
  `idempotency_key:` to supply your own.
- Parameters set to `nil` are omitted instead of being sent as the string
  `"nil"`. Send `""` to unset a field in Stripe.
- Resource IDs are URL-encoded in request paths, so an ID can't escape its
  resource path. A `nil` or empty ID raises `ArgumentError` instead of
  silently turning a retrieve into a list request.
- `Subscription.cancel(id, %{cancel_at_period_end: true})` now schedules the
  cancellation through a subscription update. Stripe's cancel endpoint doesn't
  accept that parameter.
- `Invoice.upcoming/2` used `GET /v1/invoices/upcoming`, which Stripe removed
  in API version `2025-03-31.basil` (this library's default). It now delegates
  to `Invoice.create_preview/2`.
- `Webhook.verify/3` and `Webhook.construct_event/3` return
  `{:error, "missing webhook secret"}` instead of raising when no secret is
  configured, reject non-string payloads, and require the JSON payload to be
  an object.
- Auto-pagination no longer crashes when Stripe returns `has_more: true` with
  an empty page, and emits an error for an unexpected response shape.

### Added

- `Invoice.create_preview/2`.
- `Client.get_with_params/3`, `Client.delete_with_params/3`, and `Client.path/2`.
- `:idempotency_key` and `:max_retries` request options.

### Deprecated

- `Invoice.upcoming/2`. Use `Invoice.create_preview/2`.

### Documentation

- README and the Phoenix example read `current_period_end` from subscription
  items, where it lives since API version `2025-03-31.basil`.
- New sections on retries and idempotency, and on errors during
  auto-pagination.
- HexDocs now include the changelog, the Phoenix example, and the license.

### Removed

- Unused `mox` test dependency.
