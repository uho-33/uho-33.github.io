# Debug Plan for Language Toggle and Translation Issues

## Problem Analysis

### 1. Language Toggle Not Working
- **Issue**: Button shows "switch to Chinese" but clicking has no effect
- **Potential Causes**:
  - JavaScript function not properly bound to click event
  - URL generation logic incorrect for Polyglot structure
  - Language detection not working properly
  - Browser cache preventing redirect

### 2. Translation System Issues
- **Issue**: Translation detection works but actual translation not functioning
- **Potential Causes**:
  - No API key configured (Gemini API requires authentication)
  - Auto-translation disabled in config
  - Content filter errors preventing translation processing
  - Translation processor initialization issues

### 3. English Sample Post Issues
- **Issue**: English post appears in Chinese post list and gives 404
- **Potential Causes**:
  - Polyglot URL structure misunderstanding
  - Post frontmatter incorrect
  - English post in wrong directory structure
  - Permalink generation issues

### 4. Button Styling Issues
- **Issue**: Language toggle doesn't match other sidebar buttons (missing circle background)
- **Root Cause**: Not using the same CSS classes as mode-toggle and other sidebar buttons

### 5. Polyglot Configuration Issues
- **Issue**: May not be using Polyglot correctly according to documentation
- **Investigation Needed**:
  - Review Polyglot README best practices
  - Check if directory structure follows conventions
  - Verify frontmatter usage
  - Ensure URL generation follows Polyglot patterns

## Investigation Strategy

### Phase 1: Polyglot Configuration Verification
1. Review current Polyglot setup against documentation
2. Check directory structure compliance
3. Verify frontmatter usage
4. Test basic Polyglot functionality

### Phase 2: Language Toggle Functionality
1. Debug JavaScript execution
2. Verify URL generation logic
3. Test click event binding
4. Check browser network requests

### Phase 3: Translation System
1. Verify API configuration
2. Test translation processor manually
3. Check auto-translation settings
4. Debug content filtering

### Phase 4: Styling Fixes
1. Apply correct sidebar button styling
2. Ensure visual consistency
3. Test hover and active states

### Phase 5: Post Structure Fixes
1. Correct English post placement
2. Fix URL generation
3. Test post accessibility
4. Verify bilingual navigation

## Success Criteria

- [ ] Language toggle button functions correctly (switches between languages)
- [ ] Button has consistent styling with other sidebar buttons
- [ ] English posts are accessible at correct URLs
- [ ] Translation system processes content (with proper API key)
- [ ] Polyglot directory structure follows best practices
- [ ] No 404 errors for existing posts
- [ ] Clean separation between Chinese and English post listings