# Contract: Disclaimer Placement

## Trigger Condition
Render if:
- front matter `translated: true`
OR
- `original_language` exists AND `original_language != page.lang`

## Placement Rules
1. Insert after any leading prompt/notification/include blocks (heuristic: before first `<h2>` if present).
2. If no `<h2>` exists, insert after post header metadata section.
3. Only one disclaimer per post.

## HTML Structure (example)
```
<div class="translation-disclaimer" data-original-language="zh-CN" data-provider="Gemini">
  <p>This article is a translated version from Chinese. See the <a href="/original/url">original</a>.</p>
</div>
```

## Accessibility
- No interactive elements beyond optional link to origin.
- Role not required; plain text suffices.

## Logging
- Emit `DISCLAIMER_APPLIED` info log (FR-032) with reason.

## Theming
- Use existing note/prompt styling classes if available (e.g., `notice--info`) to remain coherent with Chirpy.
