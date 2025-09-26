# Contract: Toggle Behavior

## Inputs (Rendered in HTML)
- data-original-slug (string)
- data-current-lang (string)
- data-available-langs (JSON array of strings)
- Optional: anchor elements with class `lang-link` and `data-lang` attribute for each available translation

## Action: User activates toggle
1. Determine target lang:
   - If exactly two languages (zh-CN & en): other one
   - Else (future): open menu (out of scope now)
2. If target in available list: navigate to href of corresponding anchor
3. Else: display toast once per page view

## Toast Contract
- Container id: `lang-toast-container` (created lazily)
- Role: status
- aria-live: polite
- Class: `lang-toast` (theme styling hook)
- Content localized via data attributes or inline JSON mapping

## Failure Modes
- Missing data-original-slug: toggle hidden (no JS action)
- Missing counterpart: toast with message key `translation_missing`

## Non-Goals
- No persistent queue; single active toast at a time (new replaces old)
