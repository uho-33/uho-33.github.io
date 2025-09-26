# Contract: Missing Translation Toast

## Purpose
Provide a consistent, accessible, non-blocking notification when a user requests a translation that does not exist (FR-004, FR-021, FR-031).

## Trigger
- User activates language toggle targeting a language variant not present in translation group.

## Parameters
- Position: top-center (fixed)
- Duration: 5000ms (auto-dismiss)
- Dismiss: explicit close button (aria-label="Close notification") OR Esc key
- Role: status
- aria-live: polite
- Focus behavior: No focus shift (FR-031)
- One active toast instance at a time (subsequent requests replace the message)

## Copy (Baseline)
- EN: "This post has not been translated yet."
- ZH: "该文章尚未翻译"

## DOM Structure (Example)
```
<div id="lang-toast-container" class="lang-toast-wrapper" aria-live="polite" role="status">
  <div class="lang-toast" data-lang="en">
    <span class="lang-toast__message">This post has not been translated yet.</span>
    <button type="button" class="lang-toast__close" aria-label="Close notification">×</button>
  </div>
</div>
```

## Styling Hooks
- Wrapper: `.lang-toast-wrapper`
- Toast: `.lang-toast`
- Message: `.lang-toast__message`
- Close button: `.lang-toast__close`

## Accessibility
- Esc key listener removes toast if present.
- Close button keyboard focusable (standard button element).
- No ARIA alert (polite priority to avoid interrupting reading).

## Logging
- No build-time log entry; runtime only. (Validator logs unrelated to toast.)

## Non-Goals
- No queueing system.
- No persistence across navigation.
