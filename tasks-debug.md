# Debug Tasks - Language Toggle and Translation System

## Task 1: Investigate Polyglot Configuration and Structure
**Priority**: HIGH
**Status**: TODO

### Subtasks:
- [ ] Review current `_config.yml` Polyglot settings against documentation
- [ ] Check if post directory structure follows Polyglot conventions
- [ ] Verify frontmatter usage in existing posts
- [ ] Test basic Polyglot URL generation
- [ ] Compare with Polyglot documentation examples

**Files to check**:
- `_config.yml`
- `_posts/` directory structure
- Individual post frontmatter
- Generated `_site/` structure

## Task 2: Fix Language Toggle Button Styling
**Priority**: HIGH  
**Status**: TODO

### Subtasks:
- [ ] Apply same CSS classes as `#mode-toggle` button
- [ ] Add circular background styling
- [ ] Ensure proper hover effects
- [ ] Test visual consistency with other sidebar buttons

**Target styling** (from attachment):
```css
#sidebar .sidebar-bottom #mode-toggle, #sidebar .sidebar-bottom a {
  width: 1.75rem;
  height: 1.75rem;
  margin-bottom: .5rem;
  border-radius: 50%;
  color: var(--sidebar-btn-color);
  background-color: var(--sidebar-btn-bg);
  text-align: center;
  display: flex;
  align-items: center;
  justify-content: center;
}
```

**Files to modify**:
- `_includes/language-toggle.html`

## Task 3: Debug Language Toggle JavaScript Functionality
**Priority**: HIGH
**Status**: TODO

### Subtasks:
- [ ] Add console logging to `switchLanguage()` function
- [ ] Verify click event is firing
- [ ] Check URL construction logic
- [ ] Test localStorage functionality
- [ ] Debug browser navigation
- [ ] Verify Polyglot URL patterns

**Files to check**:
- `_includes/language-toggle.html` (JavaScript section)
- Browser developer console
- Network tab for failed requests

## Task 4: Fix English Post Structure and URLs  
**Priority**: HIGH
**Status**: TODO

### Subtasks:
- [ ] Move English posts to correct Polyglot structure
- [ ] Fix post frontmatter for proper language detection
- [ ] Update permalinks to follow Polyglot conventions
- [ ] Test post accessibility at correct URLs
- [ ] Ensure posts appear in correct language sections

**Investigation points**:
- Current: `_posts/en/2024-02-14-sophomore-notes.md`
- Polyglot standard: Posts with `lang: en` in frontmatter
- URL generation: How Polyglot creates `/en/` prefixed URLs

**Files to modify**:
- `_posts/en/2024-02-14-sophomore-notes.md`
- Possibly move to `_posts/` root with proper frontmatter

## Task 5: Configure Translation System
**Priority**: MEDIUM
**Status**: TODO

### Subtasks:
- [ ] Add API key configuration documentation
- [ ] Enable auto-translation in config if desired
- [ ] Test manual translation trigger
- [ ] Verify content filtering works without errors
- [ ] Document translation workflow

**Configuration needed**:
```yaml
translation:
  auto_translate: false  # Set to true for automatic translation
  default_provider: 'gemini'
```

**Environment setup**:
```bash
export GEMINI_API_KEY="your-api-key-here"
```

## Task 6: Verify and Test Complete System
**Priority**: MEDIUM
**Status**: TODO

### Subtasks:
- [ ] Test language switching functionality
- [ ] Verify all posts are accessible
- [ ] Check bilingual navigation
- [ ] Test translation workflow (with API key)
- [ ] Validate Polyglot URL structure
- [ ] Performance test with both languages

**Test scenarios**:
1. Navigate to Chinese site root `/`
2. Click language toggle → should go to `/en/`
3. Navigate to specific Chinese post `/posts/post-name/`
4. Click language toggle → should go to `/en/posts/post-name/`
5. All English posts should be accessible
6. No 404 errors for existing content

## Task 7: Documentation and Cleanup
**Priority**: LOW
**Status**: TODO

### Subtasks:
- [ ] Document proper Polyglot usage
- [ ] Create translation workflow guide
- [ ] Add troubleshooting notes
- [ ] Clean up debug files
- [ ] Update README if necessary

## Execution Order

1. **Task 1** (Polyglot Investigation) - Must understand current issues first
2. **Task 4** (Post Structure) - Fix fundamental URL/structure problems  
3. **Task 2** (Button Styling) - Quick visual fix
4. **Task 3** (JavaScript Debug) - Core functionality fix
5. **Task 5** (Translation Config) - Optional enhancement
6. **Task 6** (System Test) - Validation
7. **Task 7** (Documentation) - Cleanup

## Notes

- Focus on getting basic bilingual structure working first
- Translation system can work without API key (just won't auto-translate)
- Polyglot handles URL generation automatically when configured properly
- Button styling is cosmetic but important for user experience