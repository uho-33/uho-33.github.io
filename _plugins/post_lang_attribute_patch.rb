require 'jekyll'

# Fix <html lang> for fallback post copies produced by jekyll-polyglot.
# When a post translation is missing, Polyglot appears to copy the rendered default-language
# HTML into /<lang>/posts/... without re-rendering layouts. That leaves <html lang="zh-CN">
# inside English directories. We patch those copies post-write.

Jekyll::Hooks.register :site, :post_write do |site|
  langs = Array(site.config['languages'])
  default_lang = site.config['default_lang'] || site.config['lang']
  next if langs.size <= 1

  dest = site.dest
  langs.each do |lang|
    next if lang == default_lang
    posts_root = File.join(dest, lang, 'posts')
    next unless Dir.exist?(posts_root)
    Dir.glob(File.join(posts_root, '**', 'index.html')).each do |html_path|
      begin
        content = File.read(html_path, mode: 'r:UTF-8')
        # Skip if already correct
        next if content.match?(/<html\s+[^>]*lang=["']#{Regexp.escape(lang)}["']/i)
        # Replace first lang attribute only
        if content =~ /<html\s+[^>]*lang=["'][^"']+["']/i
          new_content = content.sub(/(<html\s+[^>]*lang=["'])([^"']+)(["'])/i, "\\1#{lang}\\3")
          File.write(html_path, new_content, mode: 'w:UTF-8')
          Jekyll.logger.info 'LANG-TX', "HTML_LANG_PATCH file=#{html_path.sub(dest,'')} -> #{lang}"
        else
          Jekyll.logger.warn 'LANG-TX', "HTML_LANG_PATCH_MISSING_LANG_ATTR file=#{html_path.sub(dest,'')}"
        end
      rescue => e
        Jekyll.logger.warn 'LANG-TX', "HTML_LANG_PATCH_FAILED file=#{html_path.sub(dest,'')} error=#{e.class}: #{e.message}"
      end
    end
  end
end
