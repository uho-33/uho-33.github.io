# Tasks: Add English Mode with LLM Translation

**Input**: Design documents from `/specs/001-add-english-mode/`
**Prerequisites**: plan.md (required), research.md, data-model.md, contracts/

## Execution Flow (main)
```
1. Load plan.md from feature directory
   → If not found: ERROR "No implementation plan found"
   → Extract: tech stack, libraries, structure
2. Load optional design documents:
   → data-model.md: Extract entities → model tasks
   → contracts/: Each file → contract test task
   → research.md: Extract decisions → setup tasks
3. Generate tasks by category:
   → Setup: project init, dependencies, linting
   → Tests: contract tests, integration tests
   → Core: models, services, CLI commands
   → Integration: DB, middleware, logging
   → Polish: unit tests, performance, docs
4. Apply task rules:
   → Different files = mark [P] for parallel
   → Same file = sequential (no [P])
   → Tests before implementation (TDD)
5. Number tasks sequentially (T001, T002...)
6. Generate dependency graph
7. Create parallel execution examples
8. Validate task completeness:
   → All contracts have tests?
   → All entities have models?
   → All endpoints implemented?
9. Return: SUCCESS (tasks ready for execution)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions
- **Jekyll static site**: `_plugins/`, `_includes/`, `_sass/`, `assets/js/`
- **Tests**: `test/`, `spec/` or inline documentation tests
- **Data**: `_data/` for YAML configuration and cache files

## Phase 3.1: Setup
- [ ] T001 Create Jekyll plugin structure in `_plugins/translation/`
- [ ] T002 Add translation dependencies to Gemfile (http gem, yaml gem)
- [ ] T003 [P] Configure translation settings in `_config.yml`
- [ ] T004 [P] Create translation cache directory `_data/translations/`

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**
- [ ] T005 [P] Contract test for translation plugin hook in `test/translation_hook_test.rb`
- [ ] T006 [P] Contract test for language detection in `test/language_detection_test.rb`
- [ ] T007 [P] Contract test for provider configuration in `test/provider_config_test.rb`
- [ ] T008 [P] Integration test for language toggle functionality in `test/integration/language_toggle_test.rb`
- [ ] T009 [P] Integration test for pre-translated content display in `test/integration/content_display_test.rb`
- [ ] T010 [P] Integration test for real-time fallback translation in `test/integration/fallback_translation_test.rb`
- [ ] T011 [P] Integration test for mixed language preservation in `test/integration/mixed_language_test.rb`
- [ ] T012 [P] Integration test for provider configuration switch in `test/integration/provider_switch_test.rb`

## Phase 3.3: Core Implementation (ONLY after tests are failing)
- [ ] T013 [P] Translation Cache Entry model in `_plugins/translation/models/cache_entry.rb`
- [ ] T014 [P] LLM Provider Configuration model in `_plugins/translation/models/provider_config.rb`
- [ ] T015 [P] Post Translation Status model in `_plugins/translation/models/translation_status.rb`
- [ ] T016 [P] Language detection service in `_plugins/translation/services/language_detector.rb`
- [ ] T017 [P] Translation cache service in `_plugins/translation/services/cache_service.rb`
- [ ] T018 Translation service with multi-provider support in `_plugins/translation/services/translation_service.rb`
- [ ] T019 Build hook integration in `_plugins/translation/hooks/build_hook.rb`
- [ ] T020 Content processor for Chinese text detection in `_plugins/translation/processors/content_processor.rb`

## Phase 3.4: Frontend Components
- [ ] T021 [P] Language toggle button component in `_includes/language-toggle.html`
- [ ] T022 [P] Language toggle JavaScript in `assets/js/language-toggle.js`
- [ ] T023 [P] Language toggle CSS styling in `_sass/components/_language-toggle.scss`
- [ ] T024 Fallback translation JavaScript service in `assets/js/fallback-translator.js`
- [ ] T025 Update navigation template to include language toggle in `_includes/topbar.html`

## Phase 3.5: Integration & Configuration  
- [ ] T026 LLM provider API clients (Gemini, OpenAI, Claude) in `_plugins/translation/clients/`
- [ ] T027 Google Translate fallback client in `_plugins/translation/clients/google_client.rb`
- [ ] T028 Translation workflow orchestration in `_plugins/translation/workflows/build_workflow.rb`
- [ ] T029 Error handling and retry logic in `_plugins/translation/utils/error_handler.rb`
- [ ] T030 URL generation for English pages in `_plugins/translation/generators/url_generator.rb`

## Phase 3.6: Localization & UI
- [ ] T031 [P] English locale file for interface elements in `_data/locales/en.yml`
- [ ] T032 [P] Date and number formatting utilities in `_plugins/translation/utils/formatter.rb`
- [ ] T033 Update page layouts for bilingual support in `_layouts/default.html`
- [ ] T034 Update post layout for translation metadata in `_layouts/post.html`
- [ ] T035 Translation quality indicator component in `_includes/translation-quality.html`

## Phase 3.7: Polish & Documentation
- [ ] T036 [P] Unit tests for translation service in `test/unit/translation_service_test.rb`  
- [ ] T037 [P] Unit tests for language detector in `test/unit/language_detector_test.rb`
- [ ] T038 [P] Performance benchmark tests in `test/performance/translation_performance_test.rb`
- [ ] T039 [P] Update README with translation setup instructions
- [ ] T040 [P] Create troubleshooting guide in `docs/translation-troubleshooting.md`
- [ ] T041 Validate quickstart scenarios from `quickstart.md`
- [ ] T042 Cross-browser testing for language toggle functionality
- [ ] T043 Build time optimization and caching verification

## Dependencies
**Setup Phase (T001-T004)**
- All setup tasks can run in parallel except T001 must complete first

**Test Phase (T005-T012)** 
- All test tasks can run in parallel
- Tests must be written and failing before proceeding to implementation

**Core Implementation (T013-T020)**
- Models (T013-T015) can run in parallel  
- Services (T016-T018) depend on models being complete
- T019-T020 depend on services being complete

**Frontend (T021-T025)**
- T021-T023 can run in parallel (different files)
- T024 can run in parallel with T021-T023
- T025 depends on T021 (language toggle component)

**Integration (T026-T030)**
- T026-T027 can run in parallel (different client files)
- T028-T030 depend on T018 (translation service) and T026-T027

**Localization (T031-T035)**
- T031-T032 can run in parallel
- T033-T035 depend on T021 (language toggle) and T031 (locales)

**Polish (T036-T043)**
- T036-T040 can run in parallel (different files)
- T041-T043 depend on all previous implementation being complete

## Parallel Execution Examples
```
# Phase 3.2 - All tests can be launched together:
Task: "Contract test for translation plugin hook in test/translation_hook_test.rb"
Task: "Contract test for language detection in test/language_detection_test.rb"  
Task: "Contract test for provider configuration in test/provider_config_test.rb"
Task: "Integration test for language toggle functionality in test/integration/language_toggle_test.rb"

# Phase 3.3 - Models can be built in parallel:
Task: "Translation Cache Entry model in _plugins/translation/models/cache_entry.rb"
Task: "LLM Provider Configuration model in _plugins/translation/models/provider_config.rb"
Task: "Post Translation Status model in _plugins/translation/models/translation_status.rb"

# Phase 3.4 - Frontend components in parallel:
Task: "Language toggle button component in _includes/language-toggle.html"
Task: "Language toggle JavaScript in assets/js/language-toggle.js" 
Task: "Language toggle CSS styling in _sass/components/_language-toggle.scss"
```

## Notes
- [P] tasks = different files, no dependencies
- Verify all tests fail before implementing (TDD approach)
- Commit after completing each task
- Test locally with `bundle exec jekyll serve` after each phase
- Avoid: vague tasks, same file conflicts, skipping test phases

## Validation Checklist
*GATE: All items must pass before considering feature complete*

- [ ] All contract tests written and initially failing
- [ ] All integration tests cover quickstart scenarios
- [ ] All entities have corresponding model implementations
- [ ] Translation plugin hooks integrate with Jekyll build process
- [ ] Language toggle works on all page types
- [ ] Translation caching reduces build time on subsequent runs
- [ ] Fallback translation activates for untranslated content
- [ ] Provider configuration switching works without code changes
- [ ] Build completes successfully with translation enabled
- [ ] Cross-browser compatibility verified (Chrome, Firefox, Safari, Edge)