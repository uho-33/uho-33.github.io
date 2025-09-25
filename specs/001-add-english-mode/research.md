# Research: English Mode with LLM Translation

## LLM Translation Providers

### Decision: Multi-provider support with Gemini as primary
**Rationale**: Flexibility for cost optimization and quality comparison. Gemini models provide excellent Chinese-English translation quality with competitive pricing.
**Alternatives considered**: 
- Single provider (rejected - vendor lock-in risk)
- Google Translate only (rejected - lower quality for nuanced content)
- Local models only (rejected - complexity for build environment)

## Jekyll Plugin Architecture

### Decision: Custom Jekyll plugin with hooks
**Rationale**: Chirpy theme compatibility, build-time execution, GitHub Pages support through allowed plugins.
**Alternatives considered**:
- Direct theme modification (rejected - breaks updates)
- External build script (rejected - complicates deployment)
- Runtime JavaScript translation (rejected - performance impact)

## Translation Caching Strategy

### Decision: File-based cache with content hashing
**Rationale**: Persistent across builds, detects content changes automatically, simple implementation.
**Alternatives considered**:
- Database storage (rejected - overkill for static site)
- Memory-only cache (rejected - rebuilt every deploy)
- No caching (rejected - API cost and build time)

## Language Detection

### Decision: Regex-based Chinese character detection
**Rationale**: Simple, reliable for identifying Chinese text blocks while preserving other languages.
**Alternatives considered**:
- NLP language detection library (rejected - build complexity)
- Manual tagging (rejected - maintenance burden)
- Translate everything (rejected - corrupts existing English/Japanese)

## Fallback Translation Service

### Decision: Google Translate Web API for runtime fallback
**Rationale**: Reliable, fast response times, lower cost for occasional use.
**Alternatives considered**:
- Same LLM provider (rejected - potential duplicate costs)
- No fallback (rejected - poor UX for new posts)
- Client-side translation (rejected - API key exposure)

## Localization Implementation

### Decision: Jekyll i18n plugin with custom locale files
**Rationale**: Standard Jekyll approach, supports dates/formatting, maintains theme compatibility.
**Alternatives considered**:
- Manual liquid template modifications (rejected - maintenance burden)
- JavaScript-based localization (rejected - runtime overhead)
- Duplicate site structure (rejected - complexity)