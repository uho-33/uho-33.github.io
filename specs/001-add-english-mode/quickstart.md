# Quickstart: English Mode with LLM Translation

## Setup and Testing Guide

### Prerequisites
- Jekyll 4.3+ installed
- Ruby 3.0+ 
- Chirpy theme active
- LLM provider API keys (Gemini recommended)

### Environment Setup

1. **Configure API Keys**
   ```bash
   export GEMINI_API_KEY="your-gemini-key"
   export GOOGLE_TRANSLATE_KEY="your-google-key"  # fallback
   ```

2. **Update _config.yml**
   ```yaml
   translation:
     enabled: true
     default_provider: "gemini"
     fallback_provider: "google"
   ```

3. **Install Dependencies**
   ```bash
   bundle install
   ```

### Testing Scenarios

#### Scenario 1: Language Toggle Functionality
1. Start local Jekyll server: `bundle exec jekyll serve`
2. Navigate to homepage (Chinese mode by default)
3. Click language toggle button in navigation
4. **Expected**: Interface switches to English, URL updates
5. **Verify**: Language preference stored in localStorage

#### Scenario 2: Pre-translated Content Display
1. Create test post with Chinese content in `_posts/`
2. Run build process: `bundle exec jekyll build`
3. **Expected**: English version generated in `_site/en/`
4. Navigate to English post URL
5. **Verify**: Content displayed in English with preserved formatting

#### Scenario 3: Real-time Fallback Translation
1. Add new Chinese post without running full build
2. Switch to English mode
3. Navigate to new post
4. **Expected**: Real-time translation via Google Translate
5. **Verify**: Translation quality indicator shown

#### Scenario 4: Mixed Language Preservation
1. Create post with Chinese, English, and code blocks
2. Trigger translation process
3. **Expected**: Only Chinese text translated
4. **Verify**: English text and code blocks unchanged

#### Scenario 5: Provider Configuration Switch
1. Change `default_provider` in `_config.yml` from "gemini" to "claude"
2. Clear translation cache
3. Rebuild site
4. **Expected**: New translations use Claude API
5. **Verify**: Provider metadata in translation files updated

### Validation Checklist

#### Build Process
- [ ] Translation plugin loads without errors
- [ ] Chinese content detected and segmented correctly  
- [ ] API calls made only for uncached content
- [ ] Translation cache files created in `_data/translations/`
- [ ] English pages generated with correct URLs
- [ ] Build completes within reasonable time (<5 min for 50 posts)

#### User Experience  
- [ ] Language toggle button visible on all pages
- [ ] Smooth transition between language modes
- [ ] Page load times <3 seconds in both modes
- [ ] Mobile responsive design maintained
- [ ] Browser back/forward navigation works correctly
- [ ] Language preference persists across sessions

#### Content Quality
- [ ] Mathematical expressions preserved (KaTeX)
- [ ] Code syntax highlighting maintained  
- [ ] Internal links updated for English URLs
- [ ] Image alt text and captions translated
- [ ] Metadata (titles, descriptions) localized
- [ ] Date formats follow English conventions

#### Error Handling
- [ ] Graceful fallback when LLM API unavailable
- [ ] Clear error messages for configuration issues
- [ ] Partial translations display correctly
- [ ] Rate limit handling doesn't break build
- [ ] Invalid API keys don't crash Jekyll

### Performance Benchmarks

- **Cold build time**: <5 minutes for 50 posts
- **Incremental build**: <30 seconds for single post update
- **Page load time**: <3 seconds (both languages)
- **Translation cache hit rate**: >90% after initial build
- **Memory usage**: <500MB during build process

### Troubleshooting

**Issue**: Translation not appearing
- Check API key environment variables
- Verify provider configuration in `_config.yml`
- Clear cache: `rm -rf _data/translations/`

**Issue**: Build fails with API errors
- Check network connectivity
- Verify API key permissions
- Review rate limiting settings

**Issue**: Language toggle not working
- Check JavaScript console for errors
- Verify localStorage permissions
- Test in different browsers