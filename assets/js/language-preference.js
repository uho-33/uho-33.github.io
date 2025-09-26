/*!
 * Language Preference Manager
 * Handles client-side language preference persistence for bilingual Jekyll blog
 * Compatible with Jekyll-Polyglot and Chirpy theme
 */

(function (window, document) {
  'use strict';

  const LanguagePreference = {
    // Configuration
    STORAGE_KEY: 'blog_language_preference',
    DEFAULT_EXPIRY_DAYS: 30,
    SUPPORTED_LANGUAGES: ['zh-CN', 'en'],

    // Get current page language from Jekyll Polyglot
    getCurrentLanguage: function () {
      // Check for language in URL path
      const path = window.location.pathname;
      if (path.startsWith('/en/') || path === '/en') {
        return 'en';
      }

      // Check for language attribute in HTML
      const htmlLang = document.documentElement.getAttribute('lang');
      if (htmlLang && this.SUPPORTED_LANGUAGES.includes(htmlLang)) {
        return htmlLang;
      }

      // Default to Chinese
      return 'zh-CN';
    },

    // Get stored language preference
    getStoredPreference: function () {
      try {
        const stored = localStorage.getItem(this.STORAGE_KEY);
        if (!stored) return null;

        const preference = JSON.parse(stored);

        // Check if preference has expired
        if (preference.expires && new Date() > new Date(preference.expires)) {
          this.clearPreference();
          return null;
        }

        // Validate language
        if (!this.SUPPORTED_LANGUAGES.includes(preference.language)) {
          this.clearPreference();
          return null;
        }

        return preference;
      } catch (error) {
        console.warn('Failed to load language preference:', error);
        this.clearPreference();
        return null;
      }
    },

    // Store language preference
    setPreference: function (language, expiryDays) {
      expiryDays = expiryDays || this.DEFAULT_EXPIRY_DAYS;

      if (!this.SUPPORTED_LANGUAGES.includes(language)) {
        console.error('Unsupported language:', language);
        return false;
      }

      const preference = {
        language: language,
        expires: new Date(
          Date.now() + expiryDays * 24 * 60 * 60 * 1000
        ).toISOString(),
        setAt: new Date().toISOString()
      };

      try {
        localStorage.setItem(this.STORAGE_KEY, JSON.stringify(preference));

        // Dispatch custom event
        const event = new CustomEvent('languagePreferenceChanged', {
          detail: { language: language, preference: preference }
        });
        window.dispatchEvent(event);

        return true;
      } catch (error) {
        console.error('Failed to save language preference:', error);
        return false;
      }
    },

    // Clear stored preference
    clearPreference: function () {
      try {
        localStorage.removeItem(this.STORAGE_KEY);

        // Dispatch custom event
        const event = new CustomEvent('languagePreferenceCleared');
        window.dispatchEvent(event);

        return true;
      } catch (error) {
        console.error('Failed to clear language preference:', error);
        return false;
      }
    },

    // Get URL for switching to specified language
    getLanguageUrl: function (targetLanguage, currentPath) {
      currentPath = currentPath || window.location.pathname;

      // Handle root paths
      if (currentPath === '/' || currentPath === '') {
        return targetLanguage === 'en' ? '/en/' : '/';
      }

      // Handle switching to English
      if (targetLanguage === 'en') {
        // If already on English path, no change needed
        if (currentPath.startsWith('/en/')) {
          return currentPath;
        }
        // Add /en prefix
        return '/en' + currentPath;
      }

      // Handle switching to Chinese (remove /en prefix)
      if (targetLanguage === 'zh-CN') {
        if (currentPath.startsWith('/en/')) {
          const cleanPath = currentPath.substring(3); // Remove '/en'
          return cleanPath === '' ? '/' : cleanPath;
        }
        // Already on Chinese path
        return currentPath;
      }

      return currentPath;
    },

    // Apply stored language preference (redirect if necessary)
    applyPreference: function (options) {
      options = options || {};

      const stored = this.getStoredPreference();
      if (!stored) return false;

      const currentLang = this.getCurrentLanguage();
      const preferredLang = stored.language;

      // If current language matches preference, no action needed
      if (currentLang === preferredLang) {
        return true;
      }

      // Don't redirect if disabled
      if (options.noRedirect) {
        return false;
      }

      // Calculate target URL
      const targetUrl = this.getLanguageUrl(preferredLang);

      // Don't redirect to same URL
      if (targetUrl === window.location.pathname) {
        return false;
      }

      // Perform redirect
      try {
        console.log(
          'Applying language preference:',
          currentLang,
          '→',
          preferredLang
        );
        window.location.href = targetUrl;
        return true;
      } catch (error) {
        console.error('Failed to redirect for language preference:', error);
        return false;
      }
    },

    // Initialize language preference system
    init: function (options) {
      options = options || {};

      console.log('Initializing language preference system');

      // Apply stored preference on page load
      if (options.autoApply !== false) {
        this.applyPreference(options);
      }

      // Set up language toggle event handlers
      this.setupToggleHandlers();

      // Set up banner dismissal handlers
      this.setupBannerHandlers();

      // Debug logging
      if (options.debug) {
        const current = this.getCurrentLanguage();
        const stored = this.getStoredPreference();
        console.log('Language preference debug:', {
          current: current,
          stored: stored,
          supported: this.SUPPORTED_LANGUAGES
        });
      }
    },

    // Set up event handlers for language toggle buttons
    setupToggleHandlers: function () {
      // Look for language toggle links
      const toggleLinks = document.querySelectorAll(
        '[onclick*="setLanguagePreference"]'
      );

      toggleLinks.forEach((link) => {
        // Extract language from onclick attribute
        const onclickAttr = link.getAttribute('onclick');
        const langMatch = onclickAttr.match(
          /setLanguagePreference\(['"]([^'"]+)['"]\)/
        );

        if (langMatch) {
          const targetLang = langMatch[1];

          // Replace onclick with proper event handler
          link.removeAttribute('onclick');

          link.addEventListener('click', (event) => {
            event.preventDefault();

            // Store preference
            this.setPreference(targetLang);

            // Navigate to target URL
            const targetUrl = this.getLanguageUrl(targetLang);
            window.location.href = targetUrl;
          });
        }
      });

      // Global function for backward compatibility
      window.setLanguagePreference = (language) => {
        this.setPreference(language);
      };
    },

    // Set up banner dismissal handlers
    setupBannerHandlers: function () {
      const BANNER_STORAGE_KEY = 'translation_banner_dismissed';

      // Handle banner dismissal
      const banners = document.querySelectorAll('[data-translation-banner]');
      banners.forEach((banner) => {
        const dismissBtn = banner.querySelector('[data-dismiss="banner"]');
        if (dismissBtn) {
          dismissBtn.addEventListener('click', () => {
            banner.style.display = 'none';

            // Store dismissal state
            try {
              const dismissalState = {
                dismissed: true,
                timestamp: new Date().toISOString(),
                language: this.getCurrentLanguage()
              };
              localStorage.setItem(
                BANNER_STORAGE_KEY,
                JSON.stringify(dismissalState)
              );
            } catch (error) {
              console.warn('Failed to save banner dismissal state:', error);
            }
          });
        }
      });

      // Check if banner should be shown
      try {
        const dismissalState = localStorage.getItem(BANNER_STORAGE_KEY);
        if (dismissalState) {
          const state = JSON.parse(dismissalState);
          const currentLang = this.getCurrentLanguage();

          // Only hide banner if dismissed for current language
          if (state.dismissed && state.language === currentLang) {
            banners.forEach((banner) => {
              banner.style.display = 'none';
            });
          }
        }
      } catch (error) {
        console.warn('Failed to check banner dismissal state:', error);
      }

      // Clear banner dismissal when language changes
      window.addEventListener('languagePreferenceChanged', () => {
        try {
          localStorage.removeItem(BANNER_STORAGE_KEY);
        } catch (error) {
          console.warn('Failed to clear banner dismissal state:', error);
        }
      });
    },

    // Utility: Get preference statistics
    getPreferenceStats: function () {
      const stored = this.getStoredPreference();
      const current = this.getCurrentLanguage();

      return {
        current_language: current,
        stored_preference: stored ? stored.language : null,
        has_stored_preference: !!stored,
        preference_age_days: stored
          ? Math.floor(
              (new Date() - new Date(stored.setAt)) / (1000 * 60 * 60 * 24)
            )
          : null,
        expires_in_days: stored
          ? Math.floor(
              (new Date(stored.expires) - new Date()) / (1000 * 60 * 60 * 24)
            )
          : null
      };
    }
  };

  // Export to global scope
  window.LanguagePreference = LanguagePreference;

  // Auto-initialize when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function () {
      LanguagePreference.init();
    });
  } else {
    LanguagePreference.init();
  }
})(window, document);
