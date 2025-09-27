# Research: Multi-Language UI Consistency & Toggle

Date: 2025-09-26  
Spec: `specs/002-ui-language-not/spec.md`

## Topics & Decisions

### 1. Stable Translation Mapping Key
Decision: Use explicit `original_slug` front matter on every variant.  
Rationale: Deterministic group membership; slug collisions avoided; supports future languages without retroactive parsing of URLs.  
Alternatives: (a) Infer from canonical Chinese slug (breaks if renamed) (b) Use UUID in filename (no human readability).  
Status: Adopted.

### 2. Duplicate Variant Handling (FR-030)
Decision: Keep the most recently modified file; log a warning; earlier duplicates ignored.  
Rationale: Non-blocking workflow; authors can correct after build log review.  
Alternatives: Hard error (slows iteration), keep first (surprises editors).  
Status: Adopted.

### 3. Session-only Language Preference (FR-005)
Decision: Use `sessionStorage` key `lang_pref` (value = lang code) cleared automatically when tab/window closed.  
Rationale: Avoid stale preference for returning sessions; reinforces site default root Chinese; simpler than TTL logic.  
Alternatives: localStorage + TTL (introduced expiry logic complexity).  
Status: Adopted.

### 4. Disclaimer Placement (FR-026–FR-029)
Decision: Insert after any prompt/notification blocks, before first `<h2>` (or end of intro if no `<h2>`).  
Rationale: Ensures user sees disclaimer before deep reading, avoids interrupting hero/metadata header.  
Implementation: Liquid include `translation-disclaimer.html` with computed context; inserted conditionally.

### 5. Accessibility of Toast (FR-021, FR-031)
Decision: Single global container with `role="status"` + `aria-live="polite"`.  
No focus stealing; no `alert` role.  
Rationale: Non-critical informational feedback.  
Status: Adopted.

### 6. Logging Format (FR-032)
Decision: Plain line log: `LANG-TX | LEVEL | CODE | message`.  
Codes: `DUP_VARIANT`, `MISSING_ORIGIN`, `MISSING_ORIGINAL_SLUG`, `DISCLAIMER_APPLIED`.  
Rationale: Grep-friendly, minimal cognitive load.  
Alternatives: JSON (overkill, noisy for GitHub Pages logs).

### 7. Root Chinese Filtering (FR-025)
Decision: Root lists only zh-CN posts; English-only drafts not shown until Chinese variant added.  
Rationale: Maintains canonical Chinese-first policy; avoids partial category pollution.

### 8. Fallback Behavior on Missing Counterpart
Decision: Stay on current post; show toast `Translation not available yet.` (localized).  
No redirect to homepage (avoids context loss).

### 9. Build Validator Failure Modes
Decision: Only hard fail on schema corruption (nil required fields). Warnings for missing origin + duplicates.  
Rationale: Author productivity; incremental adoption.

## Open Risks & Mitigations
| Risk                                 | Impact                           | Mitigation                                                            |
| ------------------------------------ | -------------------------------- | --------------------------------------------------------------------- |
| Author forgets `original_slug`       | Orphaned variant & broken toggle | Validator warning + add quickstart checklist                          |
| Large future language expansion      | Potential performance            | Hash-based indexing O(n) fine up to thousands                         |
| Over-aggressive disclaimer placement | Visual clutter                   | Narrow condition `(translated == true)` only                          |
| JS disabled                          | No toggle behavior               | Provide static link list for available langs; hidden when JS enhances |

## Data Points / References
- Jekyll hook order: `:post_read` safe for content enumeration before generator plugins.
- Aria-live polite recommended for non-critical notifications (WAI-ARIA Authoring Practices 1.2).

## Summary
All clarifications resolved; no remaining research blockers. Proceed to Phase 1 design artifact creation.
