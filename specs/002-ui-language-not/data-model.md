# Data Model: Multi-Language UI Consistency

## Entities

### PostVariant
Represents a single markdown post variant in a specific language.
Fields:
- slug (string) – Jekyll-derived
- lang (string) – e.g. `zh-CN`, `en`
- original_slug (string) – stable group key (required)
- translated (bool) – true if machine/LLM translated or adapted
- original_language (string, optional) – source language of translation
- translation_provider (string, optional)
- translated_at (datetime/string, optional)
- last_modified_at (datetime) – from front matter or git plugin
- path (string) – file path for logging

### TranslationGroup (implicit index)
Key: original_slug
Data: { original_slug, variants: { lang => PostVariant }, latest_modified_at }
Derived Flags:
- has_origin (bool) – presence of default language variant (zh-CN)
- duplicate_langs (array) – if multiple posts share same (original_slug, lang) before pruning

### ValidatorIssue
Fields:
- level: info|warn|error
- code: enum (DUP_VARIANT, MISSING_ORIGIN, MISSING_ORIGINAL_SLUG, DISCLAIMER_APPLIED)
- original_slug
- lang (optional)
- message (string)

### UserLanguagePreferenceSession (client only)
Fields:
- key: `lang_pref`
- value: lang code (string)
- storage: sessionStorage
- lifetime: browser session

### DisclaimerSpec
Fields:
- should_render (bool)
- reason (enum: translated_flag, inferred)
- source_lang (string)
- target_lang (string)
- provider (string?)
- translated_at (string?)

## Validation Rules (Mapping FRs)
- FR-022: Every post MUST have `original_slug`; else log error (MISSING_ORIGINAL_SLUG) and skip toggle listing.
- FR-025: Root Chinese listing shows only zh-CN variants.
- FR-026/027/028: Disclaimer renders if `translated == true` OR (`original_language` defined and differs from `lang`).
- FR-029: Missing origin zh-CN variant: English may still build; log warning MISSING_ORIGIN.
- FR-030: Duplicates for (original_slug, lang): keep most recently modified; log warning DUP_VARIANT for others.
- FR-031: Toast non-intrusive: enforced in JS (role=status, aria-live polite).
- FR-032: Log line format stable: `LANG-TX | {LEVEL} | {CODE} | {message}`.

## Algorithms

### Build-Time Indexing
1. Iterate site.posts
2. Validate presence of `original_slug`; if absent: issue error, next
3. Build key group = original_slug; aggregate variant by `lang` with candidate list per lang for duplicate resolution
4. After ingest: for each group/lang with >1 variant pick latest by last_modified_at; mark others as duplicates
5. For each group: if no zh-CN variant present log MISSING_ORIGIN warning
6. Persist group map to `site.data['translation_groups']` (hash of original_slug => { langs: [list] }) for Liquid use.

### Toggle Resolution (client)
1. Current page has data attributes: `data-original-slug`, `data-current-lang`, `data-available-langs` (JSON array)
2. On toggle click: target_lang = opposite (for now only en/zh-CN; future: menu)
3. If target_lang in available: navigate to computed URL (pre-rendered anchor href)
4. Else: show toast (once per page view) with localized message.

### Disclaimer Rendering
Input: PostVariant front matter.
Condition: translated == true OR (original_language && original_language != lang)
Populate DisclaimerSpec and include partial.

## Edge Cases
- Duplicate + missing origin simultaneously: Both warnings logged.
- Post missing original_slug in English only: error; post excluded from toggle map but still renders (no toggle link).
- Future languages: groups simply accumulate additional langs; logic unchanged.

## Data Exposure to Templates
Injected via `site.data.translation_groups[original_slug].langs` and per-post front matter fields.

## Non-Goals
- No persistence beyond build artifacts.
- No runtime API; everything static.

