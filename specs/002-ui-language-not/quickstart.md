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
5. Force toggle on missing counterpart (temporarily remove variant) → toast appears, focus remains on toggle, screen reader reads message politely.  
6. Translated post shows disclaimer above first H2.  
7. Non-translated origin post has no disclaimer.  
8. Session preference: Switch to English on a list page, navigate to another page within session → English persists; close tab and reopen root → Chinese default restored.

## 5. Accessibility Checks
- Inspect toast container: `role=status`, `aria-live=polite`, no tabindex manipulation.  
- Keyboard: Toggle is focusable; activating missing translation does not move focus.  

## 6. Adding New Post Checklist
- Add front matter: `lang`, `original_slug`, `translated: true` (if applicable).  
- For translated variant: add `original_language`, optional `translation_provider`, `translated_at`.  
- Build & confirm no ERROR lines.  

## 7. Common Issues
| Symptom | Cause | Fix |
|---------|-------|-----|
| Toggle missing | No `original_slug` or single-language group | Add `original_slug` to both variants |
| Unexpected toast | Missing counterpart variant | Create counterpart or accept fallback |
| Duplicate warning | Two files with same slug/lang | Remove older or merge changes |
| Disclaimer absent | Missing `translated` flag | Add `translated: true` |

## 8. Cleanup Task (Post Launch)
- Remove any temporary debug relative_url wrappers per FR-024 (search `RELURL-TEMP`) once confirmed stable.

## 9. Future Expansion
- To add a third language, add new variants with same `original_slug`; no code changes needed besides UI toggle expansion (menu instead of binary switch).

## 10. Success Criteria
- Zero ERROR lines for baseline build.  
- All FR-001..FR-032 behaviors observable or logged.  
- No regression in Chirpy layout rendering.
