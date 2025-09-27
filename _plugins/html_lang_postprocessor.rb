require 'jekyll'

# Post-processing fix for html lang attribute on synthetic/replicated language folders.
# Strategy B produces only one physical markdown (default language) and synthetic maps for others.
# Polyglot copies pages into /<lang>/ but keeps original front matter lang, so <html lang> stays default.
# This hook rewrites the first <html lang="..."> to match the folder language for localized copies.

Jekyll::Hooks.register :site, :post_write do |site|
  languages = Array(site.config['languages'])
  default_lang = site.config['default_lang'] || site.config['lang']
  return if languages.empty? || languages.size == 1

  dest = site.dest
  languages.each do |lang|
    next if lang == default_lang
    lang_root = File.join(dest, lang)
    next unless Dir.exist?(lang_root)

    Dir.glob(File.join(lang_root, '**', '*.html')).each do |path|
      begin
        content = File.read(path, mode: 'r:UTF-8')
        # Skip if already correct
        if content.match?(/<html\s+[^>]*lang=["']#{Regexp.escape(lang)}["']/i)
          next
        end
        # Replace first lang attribute only
        if content =~ /<html\s+[^>]*lang=["'][^"']+["']/i
          new_content = content.sub(/(<html\s+[^>]*lang=["'])([^"']+)(["'])/i, "\\1#{lang}\\3")
          File.write(path, new_content, mode: 'w:UTF-8')
          Jekyll.logger.info 'LANG-TX', "HTML_LANG_PATCH file=#{path.sub(dest,'')} -> #{lang}"
        else
          Jekyll.logger.warn 'LANG-TX', "HTML_LANG_PATCH_MISSING_LANG_ATTR file=#{path.sub(dest,'')}"
        end
      rescue => e
        Jekyll.logger.warn 'LANG-TX', "HTML_LANG_PATCH_FAILED file=#{path} error=#{e.class}: #{e.message}"
      end
    end
  end
end
