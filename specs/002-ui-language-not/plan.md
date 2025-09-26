
# Implementation Plan: Multi‑Language UI Consistency & Post-level Language Toggle Fix

**Branch**: `002-ui-language-not` | **Date**: 2025-09-26 | **Spec**: `specs/002-ui-language-not/spec.md`
**Input**: Feature specification referenced above

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
Provide complete, consistent bilingual UX: root (Chinese) and `/en/` English mode must each show language‑exclusive UI + post listings, a post-level toggle must jump between counterparts using a stable `original_slug` mapping, and when missing translations occur the user remains in context with a polite toast. Add translation disclaimer for `translated: true` variants, enforce validator rules (presence of `original_slug`, duplicate collision resolution, missing origin disclaimer), session‑only language preference, and removal-path for temporary instrumentation.

Technical approach (high level):
1. Build-time Ruby plugin (validator + pagination already present) extended with translation group indexing and issue logging (plain text format per FR-032).
2. Liquid include adjustments for toggle, disclaimer insertion, filtered homepage logic (root Chinese hides English-only variants) and taxonomy scoping (already partially implemented; will harden tests).
3. Front-end JS: session-only language preference handling (sessionStorage) + accessible toast (aria-live polite, no focus steal) and toggle URL resolution fed by embedded JSON data attributes rendered at build time.
4. De-instrumentation task placeholder for post-deploy removal of defensive relative_url wrappers.
5. Extensibility: translation group data structure generic for future languages; no hardcoded EN/ZH branching beyond default-language root behavior.

## Technical Context
**Language/Version**: Ruby 3.x (Jekyll 4.3.x), Liquid templates, vanilla JS
**Primary Dependencies**: Jekyll, Chirpy Theme, jekyll-polyglot plugin (existing), custom plugins in `_plugins/`
**Storage**: Static markdown + front matter (filesystem); browser sessionStorage for preference (session only)
**Testing**: Existing manual browsing + (to add) lightweight build-time validator + optional HTML grep checks (scripted). No server runtime.
**Target Platform**: GitHub Pages build + static browser delivery
**Project Type**: Static site (single project)
**Performance Goals**: No additional blocking JS > 5KB minified; zero measurable increase in first paint; validator runtime << 1s typical (<100 posts)
**Constraints**: Must not break Chirpy upgrade path; no external network calls in plugin during build; accessible UI (aria-live polite, no forced focus)
**Scale/Scope**: O(10^2) posts across 2 languages initially; design supports N languages without structural change

Unknowns: None (all clarifications resolved)

### Polyglot Integration Strategy
We will leverage existing `jekyll-polyglot` capabilities rather than re‑implementing features:
- Use `site.languages`, `site.default_lang`, `site.active_lang` for runtime language context (no custom global for these).
- Adopt `page_id` (Polyglot feature) set equal to `original_slug` to gain automatic `page.permalink_lang` map for counterpart URLs (simplifies toggle logic).
- Rely on Polyglot's automatic relative URL rewriting; remove earlier need for defensive custom relative_url wrappers after FR-024 cleanup.
- Disable parallel localization on Windows (`parallel_localization: false`) to avoid build instability; keep design serial.
- Override (or bypass) Polyglot fallback content for root Chinese listing (FR-025) by explicitly filtering `site.posts | where: 'lang', 'zh-CN'` instead of relying on fallback visibility.
- Avoid using Polyglot fallback for missing translations in UI lists to ensure empty-state messaging (FR-019) rather than silent fallback to default language.
- Use `page.permalink_lang` to build `<link rel="alternate" hreflang="...">` tags (SEO) and feed toggle data attributes.
- Use `:polyglot, :post_write` hook optionally for summarizing translation coverage (non-blocking informational log only).

Deliberately NOT using:
- Polyglot's implicit fallback page display on variant absence (we want explicit toast + empty states).
- Language path inference (`lang_from_path`) initially; we rely on front matter `lang` for clarity and validation.

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**I. Chirpy Theme Compatibility**: PASS (All changes via includes/layout overrides/plugins—not core gem edits)
**II. Performance & User Experience**: PASS (Minimal JS; no pagination cost increase)
**III. Technical Reliability**: PASS (Validator enforces invariants; structured log lines FR-032)
**IV. Modular Development**: PASS (Validator + toggle JS isolated; disclaimer include modular)
**V. Deployment & Maintenance**: PASS (GitHub Pages compatible; no new external deps)
**VI. Multi-language Integrity**: PASS (FR-001..FR-032 implemented)

No violations identified → Complexity table empty.

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
# Option 1: Single project (DEFAULT)
src/
├── models/
├── services/
├── cli/
└── lib/

tests/
├── contract/
├── integration/
└── unit/

# Option 2: Web application (when "frontend" + "backend" detected)
backend/
├── src/
│   ├── models/
│   ├── services/
│   └── api/
└── tests/

frontend/
├── src/
│   ├── components/
│   ├── pages/
│   └── services/
└── tests/

# Option 3: Mobile + API (when "iOS/Android" detected)
api/
└── [same as backend above]

ios/ or android/
└── [platform-specific structure]
```

**Structure Decision**: Option 1 (single project). No new sub-projects required.

## Phase 0: Outline & Research
Resolved Topics (documented in `research.md`):
- `original_slug` as stable group key vs slug heuristics → chosen for deterministic mapping & future languages.
- Duplicate handling strategy → keep latest (FR-030) for low friction editing while preventing silent divergence.
- Session-only preference (FR-005) trade-off vs persistent TTL → simplifies privacy / stale state management.
- Disclaimer copy & placement (FR-026–FR-029) → after prompts, before first H2.
- Accessibility choice: aria-live polite, no focus steal (FR-031) vs focus shifting.
- Logging format simplicity (FR-032) vs structured JSON: simple lines adequate for grep usage.

Alternatives briefly evaluated (see `research.md` for rationale): localStorage TTL model; failing build on missing origin; strict duplicate hard error.

Status: COMPLETE (no outstanding unknowns).

## Phase 1: Design & Contracts
Design Outputs (created):
1. `data-model.md`
2. Contracts: validator-log-format, toggle-behavior, disclaimer-placement, index.
3. `quickstart.md`
4. No HTTP endpoints (documented in contracts/index.md).

Architectural Notes:
- Validator: executes in `:post_read` hook; builds hash `{ "#{original_slug}:#{lang}" => post }` and groups by original_slug for cross-lang checks.
- Polyglot synergy: `page_id` mirrors `original_slug`; validator ensures they match. If `page_id` missing, plugin injects it from `original_slug`.
- Toggle rendering: Prefer `page.permalink_lang` when present (Polyglot 1.8+); fallback to our group map if absent.
- Root filtering: Chinese homepage lists only posts with `lang: zh-CN`; English homepage lists posts with `lang: en`. Chinese root intentionally omits English-only posts until translation exists.
- Disclaimer inclusion: Liquid include conditional on `translated == true` OR `original_language` presence differing from current `page.lang`.
- Toast: Single global container inserted on first need; aria-live=polite; visually subtle.
 - SEO Alternates: Inject `<link rel="alternate" hreflang="...">` using `page.permalink_lang` mapping (adds value without extra crawler confusion).

Constitution Re-check after design: PASS (unchanged).

## Phase 2: Task Planning Approach
To be executed by /tasks command (not now):
1. Enumerate FR-001..FR-032 → map to implementation tasks.
2. Derive validator tasks (schema, group indexing, duplicate pruning, logging, disclaimer warnings).
3. Derive layout/include modifications tasks (toggle include, disclaimer include, homepage filter, taxonomy scoping confirmation).
4. JS tasks (preference persistence session-only, toggle logic, toast module, accessibility tests).
5. Test/validation tasks (build script checks, grep assertions, manual checklist alignment with quickstart).
6. Cleanup task for temporary instrumentation removal.
Parallelization marks [P] for independent file additions (contracts, docs, JS module, plugin file).
Estimated tasks: ~22-28.

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking
No deviations; table intentionally empty.


## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command)
- [x] Phase 1: Design complete (/plan command)
- [x] Phase 2: Task planning complete (/plan command - describe approach only)
- [x] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS
- [x] Post-Design Constitution Check: PASS
- [x] All NEEDS CLARIFICATION resolved
- [x] Complexity deviations documented (none present)

---
*Based on Constitution v1.1.2 - See `.specify/memory/constitution.md`*
