require 'jekyll'

# Fix for Jekyll-Polyglot URL generation issues
# Prevents double language prefixes and ensures proper cross-language linking

Jekyll::Hooks.register :site, :post_render do |site|
  # Clean up any double language prefixes in URLs
  languages = Array(site.config['languages']).compact
  next if languages.size <= 1

  site.pages.each do |page|
    next unless page.url

    # Check for and fix double language prefixes
    languages.each do |lang|
      double_prefix = "/#{lang}/#{lang}/"
      if page.url.start_with?(double_prefix)
        page.url = page.url.sub("/#{lang}/", '/')
        Jekyll.logger.warn 'PolyglotURLFix', "Fixed double prefix in URL: #{page.url}"
      end
    end
  end

  # Fix post URLs as well
  site.posts.docs.each do |post|
    next unless post.url

    if post.data['original_slug'] == '2024-11-29-doubt-science'
      Jekyll.logger.warn 'PolyglotURLFix', "post_render slug=#{post.data['original_slug']} url=#{post.url}"
    end

    languages.each do |lang|
      double_prefix = "/#{lang}/#{lang}/"
      if post.url.start_with?(double_prefix)
        post.url = post.url.sub("/#{lang}/", '/')
        Jekyll.logger.warn 'PolyglotURLFix', "Fixed double prefix in post URL: #{post.url}"
      end
    end
  end
end

# Post-write hook to clean up generated files
Jekyll::Hooks.register :site, :post_write do |site|
  languages = Array(site.config['languages']).compact
  next if languages.size <= 1

  dest = site.dest
  
  # Remove any accidentally created double language prefix directories
  languages.each do |lang|
    double_lang_path = File.join(dest, lang, lang)
    if Dir.exist?(double_lang_path)
      Jekyll.logger.warn 'PolyglotURLFix', "Removing double language directory: #{double_lang_path}"
      FileUtils.rm_rf(double_lang_path)
    end
  end

  site.posts.docs.each do |post|
    next unless post.output

    if post.data['original_slug'] == '2024-11-29-doubt-science'
      Jekyll.logger.warn 'PolyglotURLFix', "post_write slug=#{post.data['original_slug']} path=#{post.destination(dest)}"
    end
  end
end
