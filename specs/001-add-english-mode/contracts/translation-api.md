# Translation API Contract

## Jekyll Plugin Interface

### Translation Hook
```ruby
# Plugin hook called during Jekyll build process
def translate_content(content, source_lang, target_lang, provider_config)
  # Input validation
  raise ArgumentError unless content.is_a?(String)
  raise ArgumentError unless %w[zh en].include?(target_lang)
  
  # Output specification
  {
    translated_content: String, # Translated text with preserved formatting
    provider_used: String,      # Provider identifier
    token_count: Integer,       # Tokens consumed
    quality_score: Float,       # 0.0-1.0 quality estimate
    cached: Boolean,           # Whether result was cached
    processing_time: Float     # Time in seconds
  }
end
```

### Language Detection Hook
```ruby
# Detect Chinese content in mixed-language text
def detect_chinese_segments(content)
  # Input: String (markdown content)
  # Output: Array of Hash
  [
    {
      type: 'chinese',         # 'chinese' | 'other' | 'code' | 'math'
      content: String,         # Text segment
      start_pos: Integer,      # Character position
      end_pos: Integer,        # End position
      preserve: Boolean        # Whether to exclude from translation
    }
  ]
end
```

## Configuration Contract

### Provider Configuration Schema
```yaml
# _config.yml structure
translation:
  enabled: true
  default_provider: "gemini"
  fallback_provider: "google"
  
  providers:
    gemini:
      api_key_env: "GEMINI_API_KEY"
      model: "gemini-1.5-pro"
      endpoint: "https://generativelanguage.googleapis.com/v1beta/models"
      max_tokens: 8000
      rate_limit: 60
      
    openai:
      api_key_env: "OPENAI_API_KEY"
      model: "gpt-4"
      endpoint: "https://api.openai.com/v1/chat/completions"
      max_tokens: 4000
      rate_limit: 60  # per minute
      
    claude:
      api_key_env: "CLAUDE_API_KEY" 
      model: "claude-3-sonnet"
      endpoint: "https://api.anthropic.com/v1/messages"
      max_tokens: 4000
      rate_limit: 60
      
    google:
      api_key_env: "GOOGLE_TRANSLATE_KEY"
      endpoint: "https://translation.googleapis.com/language/translate/v2"
      rate_limit: 300
```

## Frontend Interface Contract

### Language Toggle Component
```javascript
// Language switching interface
class LanguageToggle {
  // Switch to specified language
  switchLanguage(langCode) {
    // Input: 'zh' | 'en'
    // Output: Promise<void>
    // Side effects: Update DOM, store preference, navigate if needed
  }
  
  // Get current language preference
  getCurrentLanguage() {
    // Output: 'zh' | 'en'
  }
  
  // Check if translation exists for current page
  hasTranslation(langCode, pageUrl) {
    // Input: language code, page URL
    // Output: Promise<boolean>
  }
}
```

### Fallback Translation Service
```javascript
// Real-time translation for missing content
class FallbackTranslator {
  async translateContent(content, sourceLang, targetLang) {
    // Input: content string, source/target language codes
    // Output: Promise<{translated: string, provider: string}>
    // Error handling: Return original content on failure
  }
}
```

## Response Schemas

### Translation Response
```json
{
  "success": true,
  "data": {
    "translated_content": "string",
    "provider": "openai|claude|google",
    "cached": false,
    "processing_time_ms": 1250,
    "token_count": 150,
    "quality_estimate": 0.85
  },
  "errors": []
}
```

### Error Response  
```json
{
  "success": false,
  "data": null,
  "errors": [
    {
      "code": "RATE_LIMIT_EXCEEDED",
      "message": "API rate limit exceeded, please try again later",
      "retry_after": 60
    }
  ]
}
```