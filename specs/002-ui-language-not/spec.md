# Feature Specification: Multi‑Language UI Consistency & Post-level Language Toggle Fix

**Feature Branch**: `002-ui-language-not`  
**Created**: 2025-09-26  
**Status**: Draft  
**Input**: User description: "UI doesn't change correspond to language mode (only English post shows English UI); top of English post shows literal `{# page.lang == 'en' #}`; language switch button on posts doesn't navigate to counterpart (works only for homepage filtering)."

## Execution Flow (main)
```
1. Parse user description from Input
   → If empty: ERROR "No feature description provided"
2. Extract key concepts from description
   → Identify: actors, actions, data, constraints
3. For each unclear aspect:
   → Mark with [NEEDS CLARIFICATION: specific question]
4. Fill User Scenarios & Testing section
   → If no clear user flow: ERROR "Cannot determine user scenarios"
5. Generate Functional Requirements
   → Each requirement must be testable
   → Mark ambiguous requirements
6. Identify Key Entities (if data involved)
7. Run Review Checklist
   → If any [NEEDS CLARIFICATION]: WARN "Spec has uncertainties"
   → If implementation details found: ERROR "Remove tech details"
8. Return: SUCCESS (spec ready for planning)
```

---

## ⚡ Quick Guidelines
- ✅ Focus on WHAT users need and WHY
- ❌ Avoid HOW to implement (no tech stack, APIs, code structure)
- 👥 Written for business stakeholders, not developers

### Section Requirements
- **Mandatory sections**: Must be completed for every feature
- **Optional sections**: Include only when relevant to the feature
- When a section doesn't apply, remove it entirely (don't leave as "N/A")

### For AI Generation
When creating this spec from a user prompt:
1. **Mark all ambiguities**: Use [NEEDS CLARIFICATION: specific question] for any assumption you'd need to make
2. **Don't guess**: If the prompt doesn't specify something (e.g., "login system" without auth method), mark it
3. **Think like a tester**: Every vague requirement should fail the "testable and unambiguous" checklist item
4. **Common underspecified areas**:
   - User types and permissions
   - Data retention/deletion policies  
   - Performance targets and scale
   - Error handling behaviors
   - Integration requirements
   - Security/compliance needs

---

## User Scenarios & Testing *(mandatory)*

### Primary User Story
As a bilingual reader, I want the site UI (navigation labels, buttons, taxonomy pages, pagination, etc.) to switch completely when I change language, and I want to move between a post and its translated counterpart with one click, so I can comfortably browse content in my preferred language without mixed or confusing interface elements.

### Acceptance Scenarios
1. **Given** I am viewing the root homepage (no language slug) in Chinese (default), **When** I toggle to English, **Then** I am taken to the `/en/` homepage with only English posts and fully English UI chrome (menus, labels, dates formatting, taxonomy, pagination, footer, search placeholder).
2. **Given** I am reading a Chinese post that has an English counterpart, **When** I click the language switch, **Then** I am taken directly to the English counterpart URL (not the English homepage) and the UI is fully English.
3. **Given** I am reading an English post that has a Chinese counterpart, **When** I click the language switch, **Then** I am taken directly to the Chinese counterpart URL (root path, no `/zh-CN/` slug) with fully Chinese UI.
4. **Given** I am on a post whose target-language counterpart does not exist, **When** I click the language switch, **Then** I stay on the same post and a non-blocking toast appears stating the translation is not available (no navigation occurs).
5. **Given** I previously chose English on any page, **When** I later revisit the site root `/` without a language segment within the same browser session, **Then** I am automatically shown the English homepage (`/en/`); after the session ends (browser closed), default Chinese root is shown again until I toggle.
6. **Given** I view any post (English or Chinese), **When** it renders, **Then** no raw template/Liquid syntax strings are visible.
7. **Given** I switch languages from any paginated homepage page (page N>1), **When** the target language loads, **Then** I always land on that language's page 1 (page index is not preserved).

### Edge Cases
- Post exists in one language only: toggle stays on the current post and shows a missing-translation toast (Scenario 4) with copy (EN) "This post has not been translated yet." / (ZH) "该文章尚未翻译".
- User stored preference points to English but only Chinese content currently available: show an empty English posts list with the empty‑state message (EN) "No posts yet in this language." / (ZH) "该文章尚未翻译" (UI remains English; preference retained).
- Deep links (manual URL entry) to a non‑existent translation counterpart (obsolete or never created): perform a 302 redirect to an existing available language variant URL and display the missing‑translation toast after load.
- Browser with disabled localStorage: toggle still functions (navigation) but preference is not persisted.
- Visiting `/en/` (or any language root) with zero posts in that language: render empty‑state block using the same copy as above; DO NOT fall back to another language's content.
 - Root homepage lists only Chinese (default) variants; English-only posts without Chinese translations do not appear until a Chinese version exists.
 - Translation note presence: Only posts with `translated: true` show a disclaimer/notice; origin posts (`translated: false` or missing) do not show it.

## Requirements *(mandatory)*

### Functional Requirements
- **FR-001**: The site MUST render all navigational and UI text (menus, breadcrumbs, headings like "Post", pagination labels, search placeholder, tag/category headings) in the currently active language.
- **FR-002**: The active language MUST be applied consistently on every page type (homepage, post pages, category listing, tag listing, archives, pagination pages) without mixing languages in UI chrome.
- **FR-003**: The language toggle on a post page MUST navigate directly to that post's translation when it exists.
- **FR-004**: If a direct counterpart does not exist, the toggle MUST remain on the current post and display a non-blocking toast indicating the translation is not available.
- **FR-005**: The toggle MUST persist the user language preference ONLY for the current browser session (no cross-session persistence); a new browser session MUST revert to default Chinese unless toggled again.
- **FR-006**: The system MUST NOT display raw template or Liquid syntax (e.g., `{# page.lang == 'en' #}`) in the rendered page.
- **FR-007**: The system MUST correctly infer whether the current page is in a non-default language to build the correct counterpart URL.
- **FR-008**: Counterpart resolution MUST use a stable mapping (e.g., `original_slug`) rather than heuristic string replacement alone.
- **FR-009**: The homepage content list MUST filter to only posts whose `lang` matches the active language.
- **FR-010**: Paginated list pages in each language MUST only contain posts in that language.
- **FR-011**: Switching language from any paginated homepage page MUST always navigate to page 1 of the target language (page index is never preserved).
- **FR-012**: Preference storage MUST degrade gracefully if localStorage is unavailable (toggle still changes page; no persistence).
- **FR-013**: All generated language-specific URLs MUST include the language segment only for non-default languages (e.g., `/en/...`).
- **FR-014**: The system MUST ensure that taxonomy pages (tags, categories) show only terms and counts for the active language.
- **FR-015**: The system MUST ensure search components (placeholder text, interface language) reflect the active language selection.
- **FR-016**: The toggle control MUST provide an accessible label that describes the action (e.g., "Switch to English" / "Switch to Chinese").
- **FR-017**: The toggle icon style/state (e.g., filled vs outlined) MUST visibly change to indicate the active language in addition to accessible labeling.
- **FR-018**: The toggle MUST always navigate to the opposite language version (or fallback behavior in FR-004); it MUST NOT trigger a no-op or same-language reload because the control never points to the current language.
 - **FR-019**: If preferred/active language has zero posts, homepage MUST render an empty-state in that language with message (EN) "No posts yet in this language." / (ZH) "该文章尚未翻译" and MUST NOT fall back to another language's content.
 - **FR-020**: Direct navigation (manual URL) to a non-existent translation counterpart MUST result in an HTTP 302 redirect to an existing available language variant URL followed by display of the missing-translation toast (copy per Edge Cases) in that variant's UI language.
 - **FR-021**: Missing-translation toast MUST appear when target translation is unavailable, with parameters defined in contract specification; ARIA role="status" (aria-live="polite").
 - **FR-022**: Every post MUST declare `original_slug`; build MUST fail with a clear error if any post omits it.
 - **FR-023**: `original_slug` acts as a language-neutral group key; any language (English or Chinese) may be the first authored version—there is no tracked or implied canonical "source" language even though Chinese is the default UI at root.
 - **FR-024**: Temporary defensive `relative_url` wrappers MUST be retained until first production deployment of this feature branch; thereafter they MUST be removed (tracked as a de-instrumentation task) while keeping any safe helper filter if still needed.
 - **FR-025**: Root (no language slug) homepage MUST exclude any post whose Chinese variant does not exist; English-only posts are invisible on root until a Chinese version (same `original_slug`) is published.
 - **FR-026**: Any post with front matter `translated: true` MUST render a translation disclaimer note at the top of content: (EN) "Translated from the original; nuances may be lost." / (ZH) "本文为原文的翻译版本，可能存在细微差异。" including a hyperlink to the original language variant if available.
 - **FR-027**: Posts with `translated: false` or missing `translated` field are treated as origin variants; they MUST NOT display a translation disclaimer.
 - **FR-028**: Translation disclaimer MUST appear after any preface prompt blocks but before main body headings (i.e., before the first level-2 heading) and MUST be accessible (role="note").
 - **FR-029**: If the origin variant cannot be resolved for a post with `translated: true`, the disclaimer MUST render with copy (EN) "Original missing" / (ZH) "原文缺失" (no link) and a build-time WARNING MUST be emitted.
 - **FR-030**: If more than one post shares the same (`original_slug`, `lang`) pair, the system MUST keep ONLY the post with the latest `date` value and emit a build warning listing the discarded file paths; all earlier duplicates MUST be excluded from listings, pagination, and counterpart resolution.
 - **FR-031**: Missing-translation toast and disclaimer announcements MUST NOT steal or move keyboard focus; focus remains on the triggering control. Screen readers announce via aria-live polite only.
 - **FR-032**: All validator warnings/errors MUST use a simple human-readable single-line format prefixed with `LANG-TX | LEVEL | CODE | message` (e.g., `LANG-TX | WARN | DUP_VARIANT | original_slug='x' lang='en' kept='file.md' dropped='old.md'`; `LANG-TX | ERROR | MISSING_ORIGINAL_SLUG | path='path.md'`). No structured JSON is required.

### Key Entities *(include if feature involves data)*
- **Post Translation Mapping**: Represents association (grouping) of all language variants of the same conceptual post.
   - Attributes: original_slug (group key), language code, post URL, availability flag.
   - Relationships: One group (identified by original_slug) to many language variants (each language variant is a peer; no variant is intrinsically the "source").
   - Additional Flags: translated (boolean; absent or false = origin; true = derived translation), original_language (optional informational field; does not affect canonical grouping logic).
- **User Language Preference**: Represents persisted choice for preferred interface language.
   - Attributes: language code, expiration timestamp.
   - Behavior: Read on root visits; ignored if expired or malformed.

---

## Clarifications

### Session 2025-09-26
- Q: When a user clicks the language toggle on a post that has NO counterpart translation, what should the behavior be? → A: Stay on same post; show toast/modal.
- Q: For homepage pagination when switching languages, if the current page number doesn't exist in target language, what happens? → A: Always go to page 1.
- Q: How should active language be indicated beyond tooltip? → A: Toggle icon style/state change.
- Q: What happens if user clicks toggle while already in that language? → A: Impossible state; button always targets opposite language and never reloads same page.
- Q: When preference is English but there are zero English posts, what should homepage show? → A: Empty English list with "No English posts yet" message.

### Session 2025-09-26 (Clarification Session 2)
- Q1: Direct navigation to a non-existent translation counterpart? → 302 redirect to the existing available language variant + toast (copy EN: "This post has not been translated yet." / ZH: "该文章尚未翻译").
- Q2: Empty-language post list message copy? → EN: "No posts yet in this language." / ZH: "该文章尚未翻译".
- Q3: Toast parameters? → Position top-center; 5000ms; dismiss via close button or Esc; ARIA role="status" aria-live="polite".
- Q4: Canonicality of `original_slug`? → REQUIRED for every post; build fails if missing.
- Q5: Retiring temporary `relative_url` wrappers? → Keep until first production deploy, then remove.

### Session 2025-09-26 (Clarification Session 3)
- Q1: Duplicate variants (same original_slug + lang)? → Keep latest; warn; ignore others (Option C).
- Q2: Language preference TTL? → Session only (no persistence across browser restarts) (Option D).
- Q3: Missing origin for a `translated: true` post? → Show disclaimer with "Original missing" / "原文缺失" (no link) + WARNING (Option C).
 - Q4: Toast focus & announcement behavior? → Do not move focus; rely on aria-live polite (Option A).
 - Q5: Logging format for validator output? → Simple human-readable line format with level prefix (Option A).

---

## Review & Acceptance Checklist
*GATE: Automated checks run during main() execution*

### Content Quality
- [ ] No implementation details (languages, frameworks, APIs)
- [ ] Focused on user value and business needs
- [ ] Written for non-technical stakeholders
- [ ] All mandatory sections completed

### Requirement Completeness
- [ ] No [NEEDS CLARIFICATION] markers remain
- [ ] Requirements are testable and unambiguous  
- [ ] Success criteria are measurable
- [ ] Scope is clearly bounded
- [ ] Dependencies and assumptions identified

---

## Execution Status
*Updated by main() during processing*

- [ ] User description parsed
- [ ] Key concepts extracted
- [ ] Ambiguities marked
- [ ] User scenarios defined
- [ ] Requirements generated
- [ ] Entities identified
- [ ] Review checklist passed

---
