
# Implementation Plan: Add English Mode with LLM Translation

**Branch**: `001-add-english-mode` | **Date**: 2025-09-25 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `E:\code\my-blog\uho-33.github.io\specs\001-add-english-mode\spec.md`

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path
   → If not found: ERROR "No feature spec at {path}"
2. Fill Technical Context (scan for NEEDS CLARIFICATION)
   → Detect Project Type from context (web=frontend+backend, mobile=app+api)
   → Set Structure Decision based on project type
3. Fill the Constitution Check section based on the content of the constitution document.
4. Evaluate Constitution Check section below
   → If violations exist: Document in Complexity Tracking
   → If no justification possible: ERROR "Simplify approach first"
   → Update Progress Tracking: Initial Constitution Check
5. Execute Phase 0 → research.md
   → If NEEDS CLARIFICATION remain: ERROR "Resolve unknowns"
6. Execute Phase 1 → contracts, data-model.md, quickstart.md, agent-specific template file (e.g., `CLAUDE.md` for Claude Code, `.github/copilot-instructions.md` for GitHub Copilot, `GEMINI.md` for Gemini CLI, `QWEN.md` for Qwen Code or `AGENTS.md` for opencode).
7. Re-evaluate Constitution Check section
   → If new violations: Refactor design, return to Phase 1
   → Update Progress Tracking: Post-Design Constitution Check
8. Plan Phase 2 → Describe task generation approach (DO NOT create tasks.md)
9. STOP - Ready for /tasks command
```

**IMPORTANT**: The /plan command STOPS at step 7. Phases 2-4 are executed by other commands:
- Phase 2: /tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

## Summary
Add bilingual support to Jekyll blog using Jekyll-Polyglot plugin for internationalization infrastructure combined with Gemini API for content translation. System will provide language toggle UI, maintain separate language versions, and implement build-time translation using LLM APIs with fallback mechanisms for missing content.

## Technical Context
**Language/Version**: Ruby 3.0+, Jekyll 4.3+, Liquid templating  
**Primary Dependencies**: Jekyll-Polyglot plugin, Gemini API (via GEMINI_API_KEY env var), Jekyll-Chirpy theme  
**Storage**: File-based (Markdown posts, YAML data files, static assets)  
**Testing**: Jekyll build verification, link checking, translation quality validation  
**Target Platform**: GitHub Pages, static web hosting  
**Project Type**: single (Jekyll static site)  
**Performance Goals**: Build-time translation processing, maintain current site load speeds  
**Constraints**: GitHub Pages compatibility, preserve Chirpy theme functionality, API rate limits  
**Scale/Scope**: Personal blog (~5 posts initially), bilingual (Chinese/English), extensible to more languages

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**I. Chirpy Theme Compatibility**: Feature must maintain theme compatibility and use existing hooks/customization points
**II. Performance & User Experience**: Implementation must not degrade load times or responsive design
**III. Technical Reliability**: Changes must be version-controlled, tested, and follow Jekyll best practices  
**IV. Modular Development**: Feature must be built as independent component with clear boundaries
**V. Deployment & Maintenance**: Must maintain GitHub Pages compatibility and be properly documented

## Project Structure

### Documentation (this feature)
```
specs/[###-feature]/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
```
# Jekyll Static Site Structure
_config.yml              # Main config + Polyglot settings
Gemfile                 # Ruby dependencies including jekyll-polyglot
_plugins/               # Custom translation plugins
├── translation_processor.rb
└── content_filter.rb
_data/
├── locales/           # UI translations (existing)
├── en/               # English-specific data
└── translations/     # LLM translation cache
_layouts/              # Existing Chirpy layouts
_includes/             # Language switcher components
├── language-toggle.html
└── translation-status.html  
_posts/               # Bilingual posts
├── 2024-02-14-sophomore-notes.md (zh-CN)
├── en/2024-02-14-sophomore-notes.md (English)
└── ...
_sass/                # Styling for language features
assets/js/            # Client-side language persistence
```

ios/ or android/
└── [platform-specific structure]
```

**Structure Decision**: Jekyll static site structure - integrating i18n capabilities into existing Chirpy theme architecture

## Phase 0: Outline & Research
1. **Extract unknowns from Technical Context** above:
   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task

2. **Generate and dispatch research agents**:
   ```
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context}"
   For each technology choice:
     Task: "Find best practices for {tech} in {domain}"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all NEEDS CLARIFICATION resolved

## Phase 1: Design & Contracts
*Prerequisites: research.md complete*

1. **Extract entities from feature spec** → `data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable

2. **Generate API contracts** from functional requirements:
   - For each user action → endpoint
   - Use standard REST/GraphQL patterns
   - Output OpenAPI/GraphQL schema to `/contracts/`

3. **Generate contract tests** from contracts:
   - One test file per endpoint
   - Assert request/response schemas
   - Tests must fail (no implementation yet)

4. **Extract test scenarios** from user stories:
   - Each story → integration test scenario
   - Quickstart test = story validation steps

5. **Update agent file incrementally** (O(1) operation):
   - Run `.specify/scripts/powershell/update-agent-context.ps1 -AgentType copilot`
     **IMPORTANT**: Execute it exactly as specified above. Do not add or remove any arguments.
   - If exists: Add only NEW tech from current plan
   - Preserve manual additions between markers
   - Update recent changes (keep last 3)
   - Keep under 150 lines for token efficiency
   - Output to repository root

**Output**: data-model.md, /contracts/*, failing tests, quickstart.md, agent-specific file

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:
- Load `.specify/templates/tasks-template.md` as base
- Generate Jekyll-specific tasks from design docs (contracts, data model, quickstart)
- Configuration setup tasks: Polyglot config, Gemfile updates, environment setup
- Plugin development tasks: Translation processor, content filter, language detector
- UI component tasks: Language toggle, fallback notices, SEO meta tags  
- Content processing tasks: Translation cache, batch processing, error handling
- Testing tasks: Build verification, translation quality, link checking

**Ordering Strategy**:
- Setup → Configuration → Plugins → UI Components → Content Processing → Testing
- Dependencies: Polyglot before custom plugins, plugins before UI components
- Mark [P] for parallel execution (independent files/features)

**Estimated Output**: 30 numbered, ordered tasks in tasks.md specific to Jekyll bilingual setup

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

| Violation                  | Why Needed         | Simpler Alternative Rejected Because |
| -------------------------- | ------------------ | ------------------------------------ |
| [e.g., 4th project]        | [current need]     | [why 3 projects insufficient]        |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient]  |


## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command)
- [x] Phase 1: Design complete (/plan command)
- [x] Phase 2: Task planning complete (/plan command - describe approach only)
- [ ] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS
- [x] Post-Design Constitution Check: PASS
- [x] All NEEDS CLARIFICATION resolved
- [x] Complexity deviations documented

---
*Based on Constitution v1.1.1 - See `.specify/memory/constitution.md`*
