# Tasks: Multi‑Language UI Consistency & Post-level Language Toggle Fix

**Input**: Design documents from `/specs/002-ui-language-not/`
**Prerequisites**: plan.md (required), research.md, data-model.md, contracts/

## Execution Flow (main)
```
1. Load plan.md from feature directory
   → Tech stack: Ruby/Jekyll, Liquid templates, vanilla JS
   → Structure: Jekyll static site (single project)
2. Load design documents:
   → data-model.md: PostVariant, TranslationGroup, ValidatorIssue entities
   → contracts/: validator-log-format, toggle-behavior, disclaimer-placement
   → quickstart.md: Manual verification scenarios
3. Generate tasks by category:
   → Setup: Jekyll plugin structure, dependencies
   → Tests: Contract validation, integration scenarios
   → Core: Validator plugin, Liquid includes, JS module
   → Integration: Layout modifications, data flow
   → Polish: Manual testing, cleanup tasks
4. Apply task rules:
   → Different files = mark [P] for parallel
   → Jekyll builds sequentially (no parallel builds)
   → Validation before implementation (TDD approach)
5. Number tasks sequentially (T001, T002... T047)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Paths relative to Jekyll repository root

## Phase 3.1: Setup & Structure
- [X] T001 Create Jekyll plugin file structure in `_plugins/translation_validator.rb`
- [X] T002 [P] Create Liquid include for language toggle in `_includes/language-toggle.html`
- [X] T003 [P] Create Liquid include for translation disclaimer in `_includes/translation-disclaimer.html`
- [X] T004 [P] Create JS module for language preference and toast in `assets/js/language-toggle.js`

## Phase 3.2: Contract Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These validation checks MUST be written and MUST pass/fail correctly before implementation**
- [X] T005 [P] Validator log format contract test - create `_plugins/test_translation_validator.rb` to verify `LANG-TX | LEVEL | CODE | message` format
- [X] T006 [P] Toggle behavior contract test - create manual test script `tools/test-toggle-behavior.rb` to verify data attributes
- [X] T007 [P] Disclaimer placement contract test - create manual test script `tools/test-disclaimer-placement.rb` to verify DOM insertion
- [X] T008 [P] Integration test for missing translation toast - add test scenarios to `quickstart.md` manual verification
- [X] T009 [P] Integration test for session language preference - add test scenarios to `quickstart.md` manual verification

## Phase 3.3: Core Implementation (ONLY after tests are written)
- [X] T010 Translation validator plugin core - PostVariant indexing and validation in `_plugins/translation_validator.rb`
- [X] T011 Validator logging system - implement log format contract in `_plugins/translation_validator.rb`
- [X] T012 Language toggle Liquid include - render available translations and data attributes in `_includes/language-toggle.html`
- [X] T013 Translation disclaimer Liquid include - conditional rendering logic in `_includes/translation-disclaimer.html`
- [X] T014 Language preference JS module - sessionStorage handling in `assets/js/language-toggle.js`
- [X] T015 Toast notification JS module - accessible aria-live implementation in `assets/js/language-toggle.js`

## Phase 3.4: Layout Integration
- [X] T016 Integrate language toggle into post layout - modify `_layouts/post.html`
- [X] T017 Integrate translation disclaimer into post layout - modify `_layouts/post.html`
- [X] T018 Filter homepage by language - modify `_layouts/home.html` for Chinese-only root
- [X] T019 Update English homepage filtering - ensure `/en/` shows English posts in `_layouts/home.html`
- [X] T020 Integrate session preference persistence across site navigation

## Phase 3.5: Data Flow & Validation
- [X] T021 Implement duplicate variant resolution (FR-030) - keep latest modified file
- [X] T022 Implement missing origin validation (FR-029) - warn when English lacks Chinese
- [X] T023 Implement original_slug requirement (FR-022) - error on missing field
- [X] T024 Implement disclaimer trigger logic (FR-026-029) - detect translated posts
- [/] T025 Implement 302 redirect for non-existent translation URLs (FR-020) - redirect to available variant + toast (static placeholder redirect + toast param implemented; evaluate edge cases)
 - [X] T025A Enforce `page_id == original_slug` for all posts (Polyglot integration) - inject if absent (supports permalink_lang)
 - [X] T025B Generate toggle link set using `page.permalink_lang` map when available (fallback to validator map)
 - [X] T025C Override Polyglot fallback listing: ensure no default-language fallback content leaks into non-origin language lists (FR-019, FR-025)
 - [X] T025D Insert SEO `<link rel="alternate" hreflang>` tags using `page.permalink_lang` (enhancement)

## Phase 3.6: Polish & Testing
- [X] T026 [P] Manual verification checklist (FR-009, FR-018, FR-019, FR-025) - homepage filtering behavior (documented in quickstart step 9 + T026 section)
- [X] T027 [P] Manual verification checklist (FR-003, FR-018) - toggle navigation between counterparts (quickstart Additional Checklists)
- [X] T028 [P] Manual verification checklist (FR-004, FR-021, FR-031) - toast accessibility behavior (quickstart Additional Checklists)
- [X] T029 [P] Manual verification checklist (FR-005, FR-012) - session preference persistence & storage fallback (quickstart Additional Checklists)
- [X] T030 [P] Manual verification checklist (FR-026–FR-029) - translation disclaimer placement & variants (quickstart Additional Checklists)
- [X] T031 Create cleanup task for temporary relative_url wrappers removal (FR-024) (no relics found)
- [ ] T032 Performance validation (Principle II) - ensure validator runs < 1s for current post count (< 200 posts)
- [ ] T033 Chirpy theme compatibility verification (Principle I) - ensure no breaking changes

## Phase 3.7: Additional Coverage & Tests (Uncovered FRs)
- [ ] T034 [P] Paginated list language filtering test (FR-010) - script `tools/test-paginated-filtering.rb`
- [ ] T035 [P] Page reset on language switch test (FR-011) - scenario added to `quickstart.md`
- [ ] T036 [P] Storage degradation fallback test (FR-012) - simulate blocked storage (override sessionStorage) script
- [ ] T037 [P] URL language segment rules verification test (FR-013) - grep `_site` for unintended `/zh-CN/`
- [ ] T038 [P] Taxonomy isolation test (FR-014) - verify tags/categories list only active language terms
- [ ] T039 [P] Search UI localization test (FR-015) - placeholder & interface labels
- [ ] T040 [P] Accessible label presence test (FR-016) - aria-label asserts
- [ ] T041 [P] Toggle visual state change test (FR-017) - class/state diff assertion
- [ ] T042 [P] Opposite-language navigation invariant test (FR-018) - ensure control never links to same lang
- [ ] T043 [P] Neutral group key neutrality test (FR-023) - validator ensures no zh-CN bias
- [ ] T044 [P] Raw template leakage grep test (FR-006) - search for `{#` or Liquid artifacts in `_site`
 - [X] T045 [P] permalink_lang mapping integrity test (Polyglot) - `tools/test-permalink-map.rb`
 - [X] T046 [P] hreflang tags presence & correctness test - `tools/test-hreflang.rb`
 - [X] T047 [P] Fallback suppression test - `tools/test-fallback-suppression.rb`

## Dependencies
- Setup (T001-T004) before tests (T005-T009, T034-T047 where applicable)
- Initial contract tests (T005-T009) plus extended coverage tests (T034-T047) ideally before related implementation tasks
- Core implementation (T010-T015) before layout integration (T016-T020)
- Validation feature tasks (T021-T025, T025A-D) depend on plugin core (T010-T011)
- Polyglot synergy tasks (T025A-D) before toggle enhancement validation (T045, T046)
- Includes (T012-T013) before layout integration (T016-T017)
- JS modules (T014-T015) before session persistence integration (T020) and page reset (T028)
- Additional implementation coverage (T026-T037) before manual polish (T026-T033)
- Extended tests (T034-T047) can run after initial build but before declaring Phase 4 complete

## Parallel Example
```
# Launch setup tasks together:
Task: "Create Liquid include for language toggle in _includes/language-toggle.html"
Task: "Create Liquid include for translation disclaimer in _includes/translation-disclaimer.html"
Task: "Create JS module for language preference in assets/js/language-toggle.js"

# Launch initial contract tests together:
Task: "Validator log format contract test in _plugins/test_translation_validator.rb"
Task: "Toggle behavior contract test in tools/test-toggle-behavior.rb"
Task: "Disclaimer placement contract test in tools/test-disclaimer-placement.rb"

# Launch extended coverage tests (example subset):
Task: "Paginated list language filtering test (FR-010)"
Task: "Taxonomy isolation test (FR-014)"
Task: "Search UI localization test (FR-015)"
```

## Files Modified/Created
- **New files**: `_plugins/translation_validator.rb`, `_includes/language-toggle.html`, `_includes/translation-disclaimer.html`, `assets/js/language-toggle.js`, (optional) `tools/test-*.rb`
- **Modified files**: `_layouts/post.html`, `_layouts/home.html`, taxonomy layouts (`_layouts/categories.html`, `_layouts/tags.html`), search include (e.g., `_includes/search-loader.html`), CSS or icon classes for toggle state
- **Test files**: `_plugins/test_translation_validator.rb`, `tools/test-*.rb`, updated `quickstart.md` scenarios

## Notes
- Jekyll builds are inherently sequential (no parallel builds)
- [P] tasks target different files with no shared dependencies
- Manual verification follows quickstart.md acceptance criteria
- Validator must emit logs matching contract format exactly
- All changes preserve Chirpy theme compatibility per constitution

## Critical Validation Points
1. Validator logs must match `LANG-TX | LEVEL | CODE | message` format
2. Toggle must use data attributes for JS behavior
3. Toast must be `aria-live="polite"` and non-intrusive
4. Session preference must not persist beyond browser session
5. Disclaimer must render only for `translated: true` posts
