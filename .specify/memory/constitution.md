<!--
Sync Impact Report:
- Version change: 1.1.1 → 1.1.2
- Modified principles: Added new Principle VI (Multi-language Integrity)
- Added sections: Principle VI
- Removed sections: None
- Templates requiring updates:
  ✅ spec-template.md (no update required; already language-agnostic)
  ✅ plan-template.md (no change; governance unaffected)
  ✅ tasks-template.md (add optional task tag 'i18n' – informational only)
  ✅ agent-file-template.md (no change)
- Follow-up TODOs: None
-->

# Kohi's Blog Constitution

## Core Principles

### I. Chirpy Theme Compatibility
All customizations must maintain full compatibility with the base Jekyll Chirpy theme. Preserve the theme's update path and avoid breaking changes that would prevent future theme upgrades. Use theme's existing hooks and customization points rather than direct modifications to core files.

### II. Performance & User Experience  
Website features must maintain fast load times and responsive design. Optimize all assets (images, CSS, JavaScript) and minimize HTTP requests. Ensure mobile-first responsive design and cross-browser compatibility. Implement progressive enhancement for advanced features.

### III. Technical Reliability
All website modifications must be version-controlled, tested, and documented. Implement proper error handling and fallbacks for enhanced features. Maintain backward compatibility and graceful degradation. Follow Jekyll best practices and liquid templating standards.

### IV. Modular Development
Build features as modular components that can be independently developed, tested, and deployed. Each feature should have clear boundaries and minimal dependencies. Use Jekyll's plugin architecture and include system for extensibility.

### V. Deployment & Maintenance
Maintain compatibility with GitHub Pages deployment pipeline. Ensure all dependencies are properly specified and locked. Implement automated testing for layout and functionality. Document all customizations for future maintenance.

### VI. Multi-language Integrity
All language modes (default and additional) MUST present a consistent UI: navigation, taxonomy listings, pagination, and post metadata must reflect the active language only. Language toggle MUST link to the exact counterpart post when it exists, otherwise show a clear non-blocking notice while remaining on the current content. No raw template markers or mixed-language chrome may appear. Preference persistence MUST degrade gracefully if storage is unavailable.
Rationale: Ensures a coherent bilingual experience, prevents user confusion, and establishes a stable contract for future translation automation.

## Technical Standards

Jekyll-based static site generation using Chirpy theme as foundation. Maintain existing feature support (KaTeX, syntax highlighting, Mermaid diagrams, search, PWA). Follow semantic versioning for all customizations. Use standard web technologies (HTML5, CSS3, ES6+) and avoid proprietary dependencies.

## Development Workflow

All website modifications follow Git workflow with feature branches and proper commit messages. Test changes locally before deployment. Use Jekyll's development server for local testing. Maintain separate environments for development and production.

## Governance

Constitution governs website development only, not content creation. All technical modifications must preserve Chirpy theme's core functionality and update compatibility. Breaking changes require thorough testing and documentation. Amendment process requires impact analysis on existing features and deployment pipeline.

**Version**: 1.1.2 | **Ratified**: 2025-09-25 | **Last Amended**: 2025-09-26