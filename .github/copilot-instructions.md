# uho-33.github.io Development Guidelines

Auto-generated from all feature plans. Last updated: 2025-09-25

## Active Technologies

- Ruby 3.0+, Jekyll 4.3+, Liquid templating + Jekyll Chirpy theme, Jekyll-Polyglot plugin, LLM APIs (Gemini primary, OpenAI/Claude fallback), Google Translate API (001-add-english-mode)
- File-based (Markdown posts, YAML data files, static assets, translation cache) (001-add-english-mode)

## Project Structure

```
_config.yml              # Polyglot + translation settings
_plugins/                # Custom translation processors
_data/
├── translations/        # LLM translation cache
├── locales/            # UI translations (extend existing)
└── en/                 # English-specific data
_posts/                 # Bilingual posts (zh-CN default, en/ subfolder)
_includes/              # Language switcher components
_layouts/               # Existing Chirpy layouts
```

## Commands

```bash
# Development
bundle exec jekyll serve          # Local development with translation
bundle exec jekyll build         # Build with translation processing

# Translation
export GEMINI_API_KEY="key"      # Set LLM provider API key
bundle exec jekyll build --config _config.yml,_config_translation.yml
```

## Code Style

Ruby 3.0+, Jekyll 4.3+, Liquid templating: Follow standard conventions
Jekyll-Polyglot: Use lang frontmatter, maintain URL structure consistency

## Recent Changes

- 001-add-english-mode: Added Ruby 3.0+, Jekyll 4.3+, Liquid templating + Jekyll Chirpy theme, Jekyll-Polyglot plugin, LLM APIs (Gemini/OpenAI/Claude), Google Translate API
- 001-add-english-mode: Added Ruby 3.0+, Jekyll 4.3+, Liquid templating + Jekyll Chirpy theme, Jekyll plugins, LLM APIs (OpenAI/Claude), Google Translate API

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
