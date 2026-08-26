# Notification email throttling

Each user has an `email_frequency` preference (`unlimited`, `daily`, `weekly`,
`none`), editable from their user settings page. Under a throttled setting,
notifications are buffered in the database instead of being sent, and a
scheduled run drains each recipient's buffer into **one** aggregate digest email
per period.

## Moving parts

| Piece | Responsibility |
| --- | --- |
| `NotificationService` | The send-or-buffer gate. Every `Notification` mailer send goes through it. |
| `PendingNotification` | The buffer. One row per notification held back. |
| `DigestDelivery` | The watermark. One row per address, with a unique index. |
| `SendNotificationDigest` | Drains one recipient's buffer into one email. |
| `NotificationDigestJob` | Scheduled entry point; drains everyone on a given frequency. |
| `ResolveBufferedNotifications` | Flushes or discards the buffer when the preference changes. |
| `PurgeStaleBufferedNotifications` | Sweeps rows no live schedule would deliver. |
| `Notification#notification_digest` | The digest email itself. |

## Scheduling

`config/initializers/scheduler.rb` runs, via rufus-scheduler:

- `notifications:daily_digest` — daily at 09:00 Asia/Jerusalem
- `notifications:weekly_digest` — Mondays at 09:00 Asia/Jerusalem
- `notifications:purge_stale_buffered` — Mondays at 09:30 Asia/Jerusalem

Re-running any of these by hand is safe. `DigestDelivery`, not the schedule, is
what enforces "at most one digest per recipient per period".

## Adding a notification

Add the mailer method to `Notification` as usual, then send it through the gate
rather than calling the mailer directly:

```ruby
NotificationService.call(mailer_method: :your_method,
                         recipient_email: user.email_recipient,
                         args: [record, other_record])
```

Two rules follow from how buffering works:

- **One gate call per recipient.** The throttle is per address, so a mailer that
  addresses several people must be invoked once per person. The gate narrows the
  envelope to the address whose preference it just checked, so a mailer that
  computes recipients internally cannot leak past it.
- **Arguments must be ActiveJob-serializable** (records, strings, numbers,
  arrays and hashes of those). They are stored as GlobalIDs and rehydrated when
  the digest is rendered; anything else raises at the call site.

The digest renders each item by invoking its original mailer method and
embedding the result, so there is no second set of templates to keep in sync.

## Known limitations

- The guarantee is *at most one digest per period per recipient*, not "at most
  one email from the system per day". Users on `unlimited` are unthrottled by
  design, and transactional mail (account activation, password reset, sent by
  `Astrails::Auth::Mailer`) does not pass through the gate at all. A hard global
  per-address cap would need the watermark check moved down into a mail
  interceptor.
- Two runs racing the same recipient can both deliver, producing a duplicate
  digest. Chosen deliberately over a lock: a duplicate digest is an acceptable
  failure, a dropped notification is not. Every `rescue` in
  `SendNotificationDigest` follows from that asymmetry.
- Throttling applies per address, so a user with several addresses is several
  recipients.
- Digests are capped at `Notification::DIGEST_ITEM_LIMIT` items; beyond that,
  only a count of the remainder is reported, and the capped-out rows are still
  deleted.
