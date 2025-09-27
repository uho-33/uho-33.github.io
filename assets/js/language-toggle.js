/*
 * Language toggle + preference module
 * Implements T014 (session preference) and T015 (toast notification)
 */

(function () {
  if (typeof window === 'undefined' || typeof document === 'undefined') {
    return;
  }

  const TOGGLE_SELECTOR = '[data-component="language-toggle"]';
  const TOAST_CONTAINER_ID = 'lang-toast-container';
  const STORAGE_KEY = 'lang_pref';
  const TOAST_AUTO_CLOSE_MS = 5000;

  const TOAST_MESSAGES = {
    'zh-CN': {
      missing: '该文章尚未翻译',
      close: '关闭提示'
    },
    en: {
      missing: 'This post has not been translated yet.',
      close: 'Close notification'
    }
  };

  function safeSessionStorage() {
    try {
      const { sessionStorage } = window;
      const testKey = '__lang_pref_test__';
      sessionStorage.setItem(testKey, '1');
      sessionStorage.removeItem(testKey);
      return sessionStorage;
    } catch (_error) {
      return null;
    }
  }

  const storage = safeSessionStorage();

  function getMessage(lang, key) {
    const table = TOAST_MESSAGES[lang] || TOAST_MESSAGES.en;
    return table[key] || TOAST_MESSAGES.en[key];
  }

  function ensureToastContainer() {
    let container = document.getElementById(TOAST_CONTAINER_ID);
    if (!container) {
      container = document.createElement('div');
      container.id = TOAST_CONTAINER_ID;
      container.className = 'lang-toast-wrapper';
      container.setAttribute('role', 'status');
      container.setAttribute('aria-live', 'polite');
      document.body.appendChild(container);
    }
    return container;
  }

  function clearToast(container) {
    if (!container) {
      return;
    }
    while (container.firstChild) {
      container.removeChild(container.firstChild);
    }
  }

  let toastTimer = null;

  function scheduleAutoClose(container) {
    if (toastTimer) {
      window.clearTimeout(toastTimer);
    }
    toastTimer = window.setTimeout(() => {
      clearToast(container);
    }, TOAST_AUTO_CLOSE_MS);
  }

  function showToast(lang, messageKey) {
    const container = ensureToastContainer();
    clearToast(container);

    const toast = document.createElement('div');
    toast.className = 'lang-toast';
    toast.dataset.lang = lang;

    const messageSpan = document.createElement('span');
    messageSpan.className = 'lang-toast-message';
    messageSpan.textContent = getMessage(lang, messageKey);
    toast.appendChild(messageSpan);

    const closeButton = document.createElement('button');
    closeButton.type = 'button';
    closeButton.className = 'lang-toast-close';
    closeButton.setAttribute('aria-label', getMessage(lang, 'close'));
    closeButton.innerHTML = '&times;';
    closeButton.addEventListener('click', () => {
      clearToast(container);
      if (toastTimer) {
        window.clearTimeout(toastTimer);
      }
    });
    toast.appendChild(closeButton);

    container.appendChild(toast);
    scheduleAutoClose(container);
  }

  function handleEscape(event) {
    if (event.key !== 'Escape') {
      return;
    }
    const container = document.getElementById(TOAST_CONTAINER_ID);
    if (container && container.firstChild) {
      clearToast(container);
      if (toastTimer) {
        window.clearTimeout(toastTimer);
      }
    }
  }

  document.addEventListener('keydown', handleEscape);

  function parsePermalinkMap(raw) {
    if (!raw) {
      return {};
    }

    try {
      const decoded = raw.replace(/&quot;/g, '"').replace(/&#39;/g, "'");
      return JSON.parse(decoded);
    } catch (_error) {
      return {};
    }
  }

  function determineTargetLanguage(activeLang, defaultLang, map) {
    const languages = Object.keys(map).filter(Boolean);

    if (!languages.length) {
      return null;
    }

    if (languages.length === 2) {
      return languages.find((code) => code !== activeLang) || null;
    }

    if (activeLang !== defaultLang && map[defaultLang]) {
      return defaultLang;
    }

    const fallback = languages.find((code) => code !== activeLang);
    return fallback || null;
  }

  function normaliseUrl(url) {
    if (!url) {
      return null;
    }
    return url.replace(/\/\/$/, '/');
  }

  function handleToggleClick(event) {
    event.preventDefault();

    const button = event.currentTarget;
    const { activeLang, defaultLang, permalinkMap: rawMap } = button.dataset;

    const map = parsePermalinkMap(rawMap);
    const targetLang = determineTargetLanguage(activeLang, defaultLang, map);

    if (!targetLang) {
      showToast(activeLang || defaultLang, 'missing');
      return;
    }

    const targetUrl = normaliseUrl(map[targetLang]);

    if (!targetUrl || targetUrl === window.location.pathname) {
      // Fallback: heuristic toggle by path prefix if map is missing or incorrect
      try {
        const current = window.location.pathname || '/';
        let fallback = null;

        // Ensure leading slash and single trailing slash normalization for comparison
        const withTrailingSlash = (p) => (p.endsWith('/') ? p : p + '/');
        const stripTrailingSlash = (p) => (p !== '/' && p.endsWith('/') ? p.slice(0, -1) : p);

        const cur = withTrailingSlash(current);
        const prefix = `/${targetLang}/`;
        const activePrefix = `/${activeLang}/`;

        if (targetLang === defaultLang) {
          // Remove non-default prefix, e.g., /en/foo -> /foo
          if (cur.startsWith(prefix)) {
            fallback = '/' + cur.slice(prefix.length);
          } else if (cur.startsWith(activePrefix)) {
            fallback = '/' + cur.slice(activePrefix.length);
          } else {
            fallback = '/';
          }
        } else {
          // Add target language prefix if missing, e.g., /foo -> /en/foo
          if (cur.startsWith(prefix)) {
            fallback = cur;
          } else {
            fallback = stripTrailingSlash(`/${targetLang}${cur}`);
            if (!fallback.endsWith('/')) fallback += '/';
          }
        }

        if (storage) {
          try {
            if (targetLang === defaultLang) {
              storage.removeItem(STORAGE_KEY);
            } else {
              storage.setItem(STORAGE_KEY, targetLang);
            }
          } catch (_e) {}
        }

        if (fallback) {
          window.location.assign(fallback);
          return;
        }
      } catch (_err) {}

      showToast(activeLang || defaultLang, 'missing');
      return;
    }

    if (storage) {
      try {
        if (targetLang === defaultLang) {
          storage.removeItem(STORAGE_KEY);
        } else {
          storage.setItem(STORAGE_KEY, targetLang);
        }
      } catch (_error) {
        /* ignore storage errors */
      }
    }

    window.location.assign(targetUrl);
  }

  function initToggle(button) {
    button.addEventListener('click', handleToggleClick);
  }

  function init() {
    const toggles = document.querySelectorAll(TOGGLE_SELECTOR);

    if (!toggles.length) {
      return;
    }

    toggles.forEach(initToggle);

    // T025: If redirected from a missing translation placeholder (?missing_lang=xx), show toast.
    try {
      const params = new URLSearchParams(window.location.search);
      const missing = params.get('missing_lang');
      if (missing) {
        const active = toggles[0].dataset.activeLang || missing;
        showToast(active, 'missing');
        // Clean the query param from URL (non-destructive) to avoid repeat toasts on reload.
        if (window.history && window.history.replaceState) {
          const cleanUrl = window.location.pathname + window.location.hash;
          window.history.replaceState({}, document.title, cleanUrl);
        }
      }
    } catch (_err) {
      /* ignore */
    }
  }

  document.addEventListener('DOMContentLoaded', init);
})();
