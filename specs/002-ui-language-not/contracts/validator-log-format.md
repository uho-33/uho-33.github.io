# Contract: Validator Log Format

Format: `LANG-TX | LEVEL | CODE | message`

Fields:
- LEVEL: INFO | WARN | ERROR
- CODE: one of
  - MISSING_ORIGINAL_SLUG
  - MISSING_ORIGIN
  - DUP_VARIANT
  - DISCLAIMER_APPLIED

Message Conventions:
- MISSING_ORIGINAL_SLUG: `path=<file>`
- MISSING_ORIGIN: `original_slug=<slug> missing zh-CN origin`
- DUP_VARIANT: `original_slug=<slug> lang=<lang> kept=<file_kept> dropped=<file_dropped>` (repeat per dropped)
- DISCLAIMER_APPLIED: `original_slug=<slug> lang=<lang> reason=<translated_flag|inferred>`

Line Prefix: Always exactly `LANG-TX |` (grep key).

No multiline entries; each issue independent.
