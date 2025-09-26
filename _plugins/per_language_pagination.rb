# Manual per-language pagination generator.
# Creates lightweight index pages /page/N/ (and /<lang>/page/N/ for non-default languages)
# because we replaced the built-in Jekyll paginator (which mixed languages) with
# a manual slicing implementation inside the home layout.
#
# Logic mirrors the ordering used in _layouts/home.html: pinned first (desc date),
# then unpinned (desc date), excluding hidden posts. We only create pages when
# total posts exceed the configured `paginate` size.

module Jekyll
  class PerLanguagePaginationGenerator < Generator
    priority :low

    def generate(site)
      per_page = (site.config['paginate'] || 10).to_i
      return if per_page <= 0

      # Polyglot exposes site.active_lang during each language build pass.
      lang = site.respond_to?(:active_lang) ? site.active_lang : site.config['lang']
      default_lang = site.config['default_lang'] || lang

      all_posts = site.posts.docs.select { |p| p.data['lang'] == lang }

      # Sort pinned + unpinned mirroring home layout
      pinned = all_posts.select { |p| truthy?(p.data['pin']) }
                         .sort_by { |p| p.data['date'] || Time.at(0) }
                         .reverse
      unpinned = all_posts.reject { |p| truthy?(p.data['pin']) || truthy?(p.data['hidden']) }
                           .sort_by { |p| p.data['date'] || Time.at(0) }
                           .reverse
      ordered = pinned + unpinned

      total = ordered.size
      return if total <= per_page # No extra pages needed

      total_pages = (total.to_f / per_page).ceil

      # Create synthetic pages 2..N for this language only.
      (2..total_pages).each do |num|
        dir_segments = []
        dir_segments << lang unless lang == default_lang
        dir_segments += ['page', num.to_s]
        dir = File.join(*dir_segments)

        page = Jekyll::PageWithoutAFile.new(site, site.source, dir, 'index.html')
        page.data['layout'] = 'home'
        page.data['lang'] = lang
        # Mark to avoid accidental processing if other plugins rely on paginator
        page.data['manual_paginated'] = true
        site.pages << page
      end
    end

    private

    def truthy?(val)
      case val
      when true then true
      when String then val.strip.downcase == 'true'
      else
        false
      end
    end
  end
end
