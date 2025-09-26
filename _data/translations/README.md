# Translation Cache Directory

This directory stores cached LLM translations to avoid re-translation of unchanged content.

## Structure
```
translations/
├── README.md           # This file
├── posts/             # Post translations
│   └── {post_slug}/
│       └── zh-to-en.yml
└── metadata/          # Translation metadata
    └── providers.yml  # Provider usage statistics
```

## Cache File Format
Each translation cache file (zh-to-en.yml) contains:
```yaml
source_hash: "sha256_of_original_content"
source_content: "Original Chinese text"
translated_content: "English translation"
provider: "gemini|openai|claude"
created_at: 2025-09-25T10:30:00Z
last_used: 2025-09-25T10:30:00Z
quality_score: 0.95
token_count: 150
```

## Usage
- Cache is checked before making new translation requests
- Content hash determines if re-translation is needed
- Multiple providers can have separate cache entries
- Statistics are tracked in metadata/ directory