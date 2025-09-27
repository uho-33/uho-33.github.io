require 'jekyll'

# Ensure page.lang reflects the currently active language pass produced by jekyll-polyglot.
# The polyglot plugin builds the site once per language setting site.active_lang.
# Our translation validator resets post document langs to default each pass; this hook corrects
# lang for non-default passes so templates (default.html, head.html, SEO tag) emit proper <html lang>.

module ActiveLangInjector
  def self.active(site)
    site.respond_to?(:active_lang) ? site.active_lang : nil
  end

  def self.default(site)
    site.config['default_lang'] || site.config['lang'] || 'en'
  end

  def self.apply(doc)
    site = doc.site
    active = active(site)
    return unless active
    default_lang = default(site)
    return if active.to_s.strip.empty? || active == doc.data['lang']
    # Only override when we're on a non-default pass OR lang unset/equals default.
    if active != default_lang && (doc.data['lang'].nil? || doc.data['lang'] == default_lang)
      doc.data['lang'] = active
    end
  end
end

Jekyll::Hooks.register :pages, :pre_render do |page, _payload|
  ActiveLangInjector.apply(page)
end

Jekyll::Hooks.register :documents, :pre_render do |doc, _payload|
  # Applies to posts and any other collection documents.
  ActiveLangInjector.apply(doc)
end
