# Quickstart: Multi-Language UI Consistency Feature

## 1. Prerequisites
- Ruby & bundler installed
- GEMINI_API_KEY etc. not required for validator

## 2. Build With Validator
`bundle exec jekyll build`  
Check output for lines beginning with `LANG-TX |`.

## 3. Expected Log Examples
```
LANG-TX | WARN | MISSING_ORIGIN | original_slug=platonic-representation missing zh-CN origin
LANG-TX | WARN | DUP_VARIANT | original_slug=sophomore-notes lang=en kept=2024-02-14-sophomore-notes.md dropped=2024-02-14-sophomore-notes-copy.md
LANG-TX | ERROR | MISSING_ORIGINAL_SLUG | path=_posts/2025-8-21-seikai.md
LANG-TX | INFO | DISCLAIMER_APPLIED | original_slug=necessity-of-classes lang=en reason=translated_flag
```

## 4. Manual UI Verification
1. Homepage root `/` shows only Chinese posts.  
2. English homepage `/en/` shows English posts (even if some lack Chinese counterpart).  
3. Open a bilingual post in Chinese → toggle leads to English version.  
4. Open an English-only post without Chinese origin → no toggle (or toast on attempt if UI present).  
5. Missing translation toast scenario:
	1. Temporarily rename an English post (e.g., append `_backup`) so its counterpart is absent.
	2. Build the site and open the Chinese variant.
	3. Activate the language toggle → expect an inline toast with `aria-live="polite"`, no navigation, focus remains on the toggle.
6. Translated post shows disclaimer above first H2.  
7. Non-translated origin post has no disclaimer.  
8. Session preference persistence:
	1. From `/`, switch to English via toggle and navigate to another page; English UI should remain.
	2. Close the tab/session, reopen `/` → UI returns to Chinese, verifying sessionStorage-only retention.
9. Redirect placeholder (T025): Navigate directly to `/en/posts/<slug>/` for a Chinese-only post → immediate redirect to origin with toast.

### Additional Checklists (Phase 3.6 Polish)
T026 Homepage Filtering: Confirm no English posts on `/`, no Chinese posts on `/en/`.
T027 Toggle Counterparts: For every bilingual pair ensure toggle navigates across variants and never to same lang.
T028 Toast Accessibility: Trigger missing translation toast; confirm `role=status`, `aria-live=polite`, Esc and close button dismiss without focus jump.
T029 Session Preference Fallback: In a private window with disabled Storage (DevTools emulate or run with storage blocked), toggle still navigates but preference not persisted → language resets on new tab (expected).
T030 Disclaimer Variants: Cases: translated_flag, origin_missing (simulate by renaming origin), original_language with manual translation provider; verify reason-specific text appears.
T031 Cleanup: Search project for `RELURL-TEMP` → none remaining. (No action needed.)
T032 Performance: Run `ruby tools/test-performance-validator.rb` target < 1s (adjust threshold if needed for environment). Report PASS.
T033 Theme Compatibility: Visually confirm no layout breaks in sidebar, topbar, posts, archives; no console errors.

### Extended Tests (Phase 3.7)
Use provided scripts in `tools/` (see table below). Execute after a fresh `bundle exec jekyll build`.

| Script | Covers | PASS Criteria |
| ------ | ------ | ------------- |
| `ruby tools/test-paginated-filtering.rb` | T034, T047 | Lists contain only active language posts |
| `ruby tools/test-url-language-rules.rb` | T037 | No unintended `/zh-CN/` paths in built URLs |
| `ruby tools/test-taxonomy-isolation.rb` | T038 | Category/tag pages list only active language |
| `ruby tools/test-search-localization.rb` | T039 | Search placeholder localized per language |
| `ruby tools/test-accessibility-labels.rb` | T040 | Toggle & buttons have aria-labels |
| `ruby tools/test-toggle-invariants.rb` | T041, T042 | Each toggle maps to at least one other lang |
| `ruby tools/test-group-neutrality.rb` | T043 | `original_slug` lacks language suffix bias |
| `ruby tools/test-template-leakage.rb` | T044 | No raw Liquid delimiters in `_site` |
| `ruby tools/test-permalink-map.rb` | T045 | `permalink_lang` maps valid languages |
| `ruby tools/test-hreflang.rb` | T046 | hreflang set matches language map |
| `ruby tools/test-fallback-suppression.rb` | T047 | Confirms no fallback leakage |
| `ruby tools/test-performance-validator.rb` | T032 | Runtime threshold |

Storage Degradation (T036): Manually open DevTools → Application → clear & simulate blocked cookies/storage (or use a browser profile with storage disabled). Confirm toggle still works (navigation relies on links), but preference resets on new tab → expected fallback.
## 5. Accessibility Checks
- Inspect toast container: `role=status`, `aria-live=polite`, no tabindex manipulation.  
- Keyboard: Toggle is focusable; activating missing translation does not move focus.  

## 6. Adding New Post Checklist
- Add front matter: `lang`, `original_slug`, `translated: true` (if applicable).  
- For translated variant: add `original_language`, optional `translation_provider`, `translated_at`.  
- Build & confirm no ERROR lines.  

## 7. Common Issues
| Symptom           | Cause                                       | Fix                                   |
| ----------------- | ------------------------------------------- | ------------------------------------- |
| Toggle missing    | No `original_slug` or single-language group | Add `original_slug` to both variants  |
| Unexpected toast  | Missing counterpart variant                 | Create counterpart or accept fallback |
| Duplicate warning | Two files with same slug/lang               | Remove older or merge changes         |
| Disclaimer absent | Missing `translated` flag                   | Add `translated: true`                |

## 8. Cleanup Task (Post Launch)
- Remove any temporary debug relative_url wrappers per FR-024 (search `RELURL-TEMP`) once confirmed stable.

## 9. Future Expansion
- To add a third language, add new variants with same `original_slug`; no code changes needed besides UI toggle expansion (menu instead of binary switch).

## 10. Success Criteria
- Zero ERROR lines for baseline build.  
- All FR-001..FR-032 behaviors observable or logged.  
- No regression in Chirpy layout rendering.
