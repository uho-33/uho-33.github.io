# Tasks: Add English Mode with LLM Translation

**Input**: Design documents from `E:\code\my-blog\uho-33.github.io\specs\001-add-english-mode\`
**Prerequisites**: plan.md (required), research.md, data-model.md, contracts/

## Execution Flow (main)
```
1. Load plan.md from feature directory
   → Tech stack: Jekyll 4.3+, Jekyll-Polyglot, Gemini API, Chirpy theme
   → Structure: Jekyll static site with bilingual support
2. Load design documents:
   → data-model.md: Translation Cache, LLM Config, User Preference, Post Status
   → contracts/translation-api.md: Jekyll plugin interfaces, config schema
   → quickstart.md: Language toggle, content display, fallback, preservation tests
3. Generate Jekyll-specific tasks:
   → Setup: Polyglot installation, config, dependencies
   → Tests: Build verification, translation quality, UI functionality
   → Core: Translation plugins, language components, cache system
   → Integration: Theme integration, API connections, error handling
   → Polish: Documentation, optimization, validation
4. Applied task rules:
   → Independent files marked [P] for parallel execution
   → Shared files sequential (no [P])
   → Tests before implementation (TDD approach)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions
- **Jekyll site structure**: Repository root with standard Jekyll directories
- **Plugins**: `_plugins/` directory for custom Ruby plugins
- **Data**: `_data/` for YAML configuration and cache files
- **Layouts/Includes**: `_layouts/` and `_includes/` for theme integration

## Phase 3.1: Setup & Configuration
- [ ] T001 Install Jekyll-Polyglot gem in Gemfile
- [ ] T002 Configure Polyglot settings in _config.yml for zh-CN/en languages
- [ ] T003 [P] Create English locale file at _data/locales/en.yml
- [ ] T004 [P] Set up translation cache directory structure _data/translations/
- [ ] T005 [P] Configure LLM provider settings in _config.yml with Gemini as primary

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**
- [ ] T006 [P] Create Jekyll build test in test/build_test.rb to verify bilingual site generation
- [ ] T007 [P] Create translation plugin test in test/translation_test.rb for translate_content hook
- [ ] T008 [P] Create language detection test in test/detection_test.rb for detect_chinese_segments
- [ ] T009 [P] Create UI integration test in test/ui_test.rb for language toggle functionality


## Phase 3.3: Core Implementation (ONLY after tests are failing)
- [ ] T010 [P] Create translation processor plugin in _plugins/translation_processor.rb
- [ ] T011 [P] Create content filter plugin in _plugins/content_filter.rb  
- [ ] T012 [P] Create language toggle component in _includes/language-toggle.html
- [ ] T013 [P] Create translation cache manager in _plugins/cache_manager.rb
- [ ] T014 Integrate Gemini API client in _plugins/gemini_translator.rb
- [ ] T015 Create LLM provider configuration loader in _plugins/provider_config.rb
- [ ] T016 Add language preference persistence in assets/js/language-preference.js


## Phase 3.4: Theme Integration & UI
- [ ] T017 Modify sidebar layout in _includes/sidebar.html to include language toggle
- [ ] T018 Update topbar layout in _includes/topbar.html to place language toggle in top right near search button
- [ ] T019 [P] Create translation notice component in _includes/translation-notice.html
- [ ] T020 [P] Create closeable LLM translation banner in _includes/translation-banner.html
- [ ] T021 [P] Add English-specific data files in _data/en/ directory
- [ ] T022 Update post layout in _layouts/post.html for language-specific content
- [ ] T023 Add SEO meta tags for language alternatives in _includes/head.html

## Phase 3.5: Content Processing & Error Handling  
- [ ] T024 Implement Chinese content detection in _plugins/content_detector.rb
- [ ] T025 Create batch translation processor for existing posts in _plugins/batch_processor.rb
- [ ] T026 Implement translation quality validation and error recovery in _plugins/quality_validator.rb
- [ ] T027 Create build hooks for automatic translation processing in _plugins/build_hooks.rb

## Phase 3.6: Testing & Validation
- [ ] T028 [P] Create manual testing checklist based on quickstart scenarios
- [ ] T029 [P] Add link validation for bilingual URLs
- [ ] T030 [P] Create performance benchmarks for build-time translation
- [ ] T031 Verify GitHub Pages compatibility and deployment
- [ ] T032 [P] Update project documentation in README.md



## Dependencies
- Setup (T001-T005) before all other phases
- Tests (T006-T009) before implementation (T010-T025) 
- Core plugins (T010-T015) before theme integration (T016-T021)
- Content processing (T022-T025) requires core plugins complete
- T014 (Gemini API) blocks T023 (batch processing)
- T012 (language toggle) blocks T016-T017 (theme integration)
- Testing (T026-T030) after all implementation complete

## Parallel Execution Examples

### Phase 3.1 Setup (can run together):
```
Task: "Configure Polyglot settings in _config.yml for zh-CN/en languages"
Task: "Create English locale file at _data/locales/en.yml" 
Task: "Set up translation cache directory structure _data/translations/"
Task: "Configure LLM provider settings in _config.yml with Gemini as primary"
```

### Phase 3.2 Tests (can run together):
```
Task: "Create Jekyll build test in test/build_test.rb to verify bilingual site generation"
Task: "Create translation plugin test in test/translation_test.rb for translate_content hook"  
Task: "Create language detection test in test/detection_test.rb for detect_chinese_segments"
Task: "Create UI integration test in test/ui_test.rb for language toggle functionality"
```

### Phase 3.3 Core Implementation (independent files):
```
Task: "Create translation processor plugin in _plugins/translation_processor.rb"
Task: "Create content filter plugin in _plugins/content_filter.rb"
Task: "Create language toggle component in _includes/language-toggle.html" 
Task: "Create translation cache manager in _plugins/cache_manager.rb"
```

## Notes
- [P] tasks target different files with no dependencies
- Verify Jekyll tests fail before implementing plugins
- Test each plugin individually before integration
- Commit after each task completion
- Maintain Chirpy theme compatibility throughout
- Use GEMINI_API_KEY environment variable for API access

## Task Generation Rules
*Applied during task creation*

1. **From Translation API Contract**:
   - translate_content hook → translation processor plugin [P]
   - detect_chinese_segments → content filter plugin [P]
   - Configuration schema → provider config loader

2. **From Data Model Entities**:
   - Translation Cache Entry → cache manager plugin [P]
   - LLM Provider Configuration → config loader [P]
   - User Language Preference → JavaScript preference handler [P]
   - Post Translation Status → build integration hooks

3. **From Quickstart Scenarios**:
   - Language toggle test → UI integration test [P]
   - Pre-translated content → build verification test [P]
   - Mixed language preservation → content detection test [P]

4. **Ordering Principles**:
   - Setup → Tests → Plugins → UI → Content Processing → Validation
   - Jekyll build dependencies: Config before plugins before layouts
   - API dependencies: Provider config before API clients

## Validation Checklist
*GATE: Verified before task completion*

- [x] All contract hooks have corresponding plugin implementations
- [x] All data entities have management components  
- [x] All tests written before implementation
- [x] Parallel tasks target independent files
- [x] Each task specifies exact Jekyll file path
- [x] No task modifies same file as another [P] task
- [x] Chirpy theme compatibility maintained throughout
- [x] GitHub Pages deployment compatibility verified