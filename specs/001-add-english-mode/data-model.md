# Data Model: English Mode with LLM Translation

## Core Entities

### Translation Cache Entry
**Purpose**: Store translated content to avoid re-translation
**Fields**:
- `source_hash`: SHA-256 hash of original Chinese content
- `source_content`: Original Chinese text
- `translated_content`: English translation
- `provider`: LLM provider used (openai, claude, etc.)
- `created_at`: Translation timestamp
- `last_used`: Last access timestamp
- `quality_score`: Optional quality rating (1-5)

**Storage**: YAML files in `_data/translations/`
**Key**: `{post_id}_{content_hash}.yml`

### LLM Provider Configuration
**Purpose**: Store API settings for different translation providers
**Fields**:
- `name`: Provider identifier (gemini, openai, claude, google)
- `api_key_env`: Environment variable name for API key
- `endpoint`: API endpoint URL
- `model`: Model identifier (gemini-1.5-pro, gpt-4, claude-3, etc.)
- `max_tokens`: Token limit per request
- `rate_limit`: Requests per minute
- `cost_per_token`: Pricing information
- `enabled`: Active status

**Storage**: `_config.yml` under `translation_providers:`
**Key**: Provider name

### User Language Preference
**Purpose**: Track visitor's chosen language mode
**Fields**:
- `language`: Selected language code (zh, en)
- `expires`: Session expiration timestamp
- `fallback_preference`: Behavior for untranslated content

**Storage**: Browser localStorage
**Key**: `blog_language_preference`

### Post Translation Status
**Purpose**: Track translation status of blog posts
**Fields**:
- `post_id`: Unique post identifier
- `source_language`: Original language (zh-CN)
- `target_language`: Translation language (en)
- `status`: Translation state (pending, completed, failed)
- `translation_path`: Path to translated file
- `last_modified`: Source content modification time
- `needs_retranslation`: Boolean flag for content changes

**Storage**: YAML file `_data/translation_status.yml`
**Key**: `{post_id}_{target_language}`

## Relationships

```
Post (1) ←→ (0..1) Translation Cache Entry
Post (1) ←→ (1) Post Translation Status
LLM Provider Configuration (1) ←→ (0..*) Translation Cache Entry
User Language Preference (1) ←→ (0..*) Page Views
```

## State Transitions

### Translation Lifecycle
1. **New Post**: `status: pending` → Detect Chinese content
2. **Build Process**: `pending` → `processing` → `completed`|`failed`
3. **Content Update**: `completed` → `pending` (if source changed)
4. **Retranslation**: `failed` → `pending` → retry process

### User Session
1. **First Visit**: Default to Chinese mode
2. **Language Toggle**: Switch mode, store preference
3. **Page Navigation**: Apply preference, load appropriate content
4. **Missing Translation**: Fall back to real-time translation

## Validation Rules

- `source_hash` must be unique per post
- `api_key_env` must reference existing environment variable
- `translation_path` must exist for `status: completed`
- `quality_score` must be between 1-5 if present
- Language codes must follow ISO 639-1 standard