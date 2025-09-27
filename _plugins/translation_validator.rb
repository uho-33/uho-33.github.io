require 'time'
require 'date'
require 'json'
require 'fileutils'

module Jekyll
  module TranslationValidator
    # Simple data holder for a post variant
    PostVariant = Struct.new(
      :original_slug, :lang, :path, :mtime, :is_translated, :original_language,
      :translation_provider, :translated_at, :doc,
      keyword_init: true
    )

    class LogFormatter
      LEVEL_MAP = {
        info: 'INFO', warn: 'WARN', error: 'ERROR'
      }.freeze

      def line(level, code, message)
        lvl = LEVEL_MAP.fetch(level.to_sym) { level.to_s.upcase }
        "LANG-TX | #{lvl} | #{code} | #{message}"
      end
    end

    class Plugin
      def self.run(site)
        new(site).run
      end

      def initialize(site)
        @site = site
        @logger = LogFormatter.new
        @default_lang = @site.config['default_lang'] || @site.config['lang'] || 'zh-CN'
        @groups = Hash.new { |hash, key| hash[key] = [] }
        @fatal_docs = []
      end

      def run
        start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        collect_variants
  prune_fatal_docs

        resolve_duplicates
  warn_missing_origin
        build_permalink_map
        persist_group_data
    inject_disclaimer_info
  generate_missing_redirects # T025: create placeholder redirect pages for missing translations
    finish_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    duration_ms = ((finish_time - start_time) * 1000.0).round(2)
        metrics = {
      'version' => 1,
      'generated_at' => Time.now.utc.iso8601,
      'duration_ms' => duration_ms,
      'groups' => @groups.size,
      'posts_total' => @site.posts.docs.size,
      'languages' => Array(@site.config['languages'])
    }
        @site.data['translation_metrics'] = metrics
        # Persist metrics JSON for external tooling (performance tests)
        begin
          metrics_path = File.join(@site.dest, 'translation-metrics.json')
          File.write(metrics_path, JSON.pretty_generate(metrics), mode: 'w:UTF-8')
        rescue => e
          log(:warn, :METRICS_WRITE_FAILED, e.message)
        end
    log(:info, :METRICS, "translation_validator duration_ms=#{duration_ms} groups=#{@groups.size} posts=#{@site.posts.docs.size}")
      end

      private

      def collect_variants
        supported_langs = Array(@site.config['languages']).reject { |l| l.nil? || l.to_s.strip.empty? }
        @site.posts.docs.each do |doc|
          fm = doc.data
          raw_lang = fm['lang']
          derived_lang = nil
          if (raw_lang.nil? || raw_lang.to_s.strip.empty?) && doc.respond_to?(:url) && doc.url
            derived_lang = supported_langs.find { |lc| doc.url.start_with?("/#{lc}/") }
          end
          lang = (raw_lang || derived_lang || @default_lang).to_s
          original_slug = (fm['original_slug'] || '').to_s.strip

          if original_slug.empty?
            log(:error, :MISSING_ORIGINAL_SLUG, "path=#{relative_path(doc)}")
            @fatal_docs << doc
            next
          end

          fm['original_slug'] = original_slug
          fm['lang'] = lang
          fm['page_id'] = original_slug

          variant = PostVariant.new(
            original_slug: original_slug,
            lang: lang,
            path: relative_path(doc),
            mtime: variant_timestamp(doc),
            is_translated: truthy?(fm['translated']),
            original_language: fm['original_language'],
            translation_provider: fm['translation_provider'],
            translated_at: fm['translated_at'],
            doc: doc
          )

          @groups[original_slug] << variant
        end
      end

      def resolve_duplicates
        @groups.each do |slug, variants|
          grouped = variants.group_by(&:lang)
          trimmed = []

          grouped.each do |lang, list|
            next if list.empty?

            sorted = list.sort_by { |variant| [primary_sort_time(variant), variant.mtime] }.reverse
            keep = sorted.first
            trimmed << keep

            sorted.drop(1).each do |duplicate|
              log(:warn, :DUP_VARIANT,
                  "original_slug=#{slug} lang=#{lang} kept=#{relative_path(keep.doc)} dropped=#{relative_path(duplicate.doc)}")
              @site.posts.docs.delete(duplicate.doc)
            end
          end

          @groups[slug] = trimmed
        end
      end

      def warn_missing_origin
        @groups.each do |slug, variants|
          next if variants.any? { |variant| variant.lang == @default_lang }
          log(:warn, :MISSING_ORIGIN, "original_slug=#{slug} missing #{@default_lang} origin")
        end
      end

      def build_permalink_map
        supported = Array(@site.config['languages']).reject(&:nil?)
        return if supported.empty?

        @groups.each_value do |variants|
          # Determine canonical base path from default language variant if present else first variant
          origin_variant = variants.find { |v| v.lang == @default_lang } || variants.first
          next unless origin_variant
          origin_url = ensure_leading_slash(finalize_url(origin_variant.doc.url, origin_variant.doc))

          # Normalize base path (strip any leading /<lang> for non-default origin)
          content_path = origin_url.dup
          supported.each do |lang_code|
            prefix = "/#{lang_code}/"
            if content_path.start_with?(prefix)
              content_path = content_path.sub(prefix, '/')
              break
            end
          end
          # content_path now like /posts/slug/ (leading slash retained)

            map = {}
          variants.each do |variant|
            variant_url = ensure_leading_slash(finalize_url(variant.doc.url, variant.doc))
            # For the default language, always use the normalized content_path to avoid language prefixes
            if variant.lang == @default_lang
              map[variant.lang] = ensure_leading_slash(content_path)
            else
              map[variant.lang] = variant_url
            end
          end

          synthetic_langs = []
          supported.each do |lang|
            next if map.key?(lang)
            if lang == @default_lang
              # Expected default path is content_path
              map[lang] = ensure_leading_slash(content_path)
            else
              # Prepend lang prefix
              normalized = content_path == '/' ? '/' : content_path
              map[lang] = ensure_leading_slash("/#{lang}#{normalized}")
            end
            synthetic_langs << lang
          end

          variants.each do |variant|
            existing = variant.doc.data['translation_permalink_map'] || {}
            variant.doc.data['translation_permalink_map'] = existing.merge(map)
            variant.doc.data['translation_permalink_map_synthetic'] = synthetic_langs unless synthetic_langs.empty?
          end
        end
      end

      def persist_group_data
        translation_groups = {}

        @groups.each do |slug, variants|
          langs = variants.map(&:lang).uniq.sort
          permalink_map = variants.each_with_object({}) do |variant, acc|
            acc[variant.lang] = ensure_leading_slash(finalize_url(variant.doc.url, variant.doc))
          end
          translation_groups[slug] = {
            'original_slug' => slug,
            'langs' => langs,
            'permalink_map' => permalink_map
          }
        end

        @site.data['translation_groups'] = translation_groups
      end

      def inject_disclaimer_info
        @groups.each do |slug, variants|
          origin = variants.find { |variant| variant.lang == @default_lang }

          variants.each do |variant|
            fm = variant.doc.data

            needs_disclaimer = variant.is_translated || (variant.original_language && variant.original_language != variant.lang)

            if needs_disclaimer
              origin_url = if origin
                             # For English posts, origin should point to Chinese version (default lang)
                             # For Chinese posts, origin should point to English version if available
                             if variant.lang == 'en' && origin.lang == @default_lang
                               # English post -> point to Chinese original
                               # Use the actual URL from the origin document
                               ensure_leading_slash(origin.doc.url)
                             elsif variant.lang == @default_lang
                               # Chinese post -> point to English version if available
                               en_variant = variants.find { |v| v.lang == 'en' }
                               en_variant ? ensure_leading_slash(en_variant.doc.url) : ensure_leading_slash(origin.doc.url)
                             else
                               ensure_leading_slash(origin.doc.url)
                             end
                           elsif variant.original_language
                             target = variants.find { |v| v.lang == variant.original_language }
                             target ? ensure_leading_slash(target.doc.url) : nil
                           end

              disclaimer_reason = if origin_url.nil?
                                     'origin_missing'
                                   elsif variant.is_translated
                                     'translated_flag'
                                   else
                                     'original_language'
                                   end

              fm['translation_disclaimer'] = {
                'should_render' => true,
                'reason' => disclaimer_reason,
                'source_lang' => variant.original_language || @default_lang,
                'target_lang' => variant.lang,
                'provider' => variant.translation_provider,
                'translated_at' => variant.translated_at,
                'origin_url' => origin_url
              }

              log_reason = variant.is_translated ? 'translated_flag' : 'inferred'
              log(:info, :DISCLAIMER_APPLIED,
                  "original_slug=#{slug} lang=#{variant.lang} reason=#{log_reason}")
            else
              fm['translation_disclaimer'] = { 'should_render' => false }
            end
          end
        end
      end

      # T025: Generate static redirect placeholder pages for missing translations.
      # For each group that has an origin (default language variant) but lacks another language variant, we
      # create /<lang>/<origin_url> index.html that immediately redirects (meta + JS) to the origin with a
      # query param ?missing_lang=<requested>. This lets frontend JS show a toast on arrival.
      def generate_missing_redirects
        langs = Array(@site.config['languages'])
        return if langs.size <= 1

        @groups.each do |_slug, variants|
          origin = variants.find { |v| v.lang == @default_lang }
          next unless origin

            present_langs = variants.map(&:lang)
          missing = langs - present_langs
          # Only generate placeholders for non-default languages; default missing handled by content itself
          missing.reject! { |l| l == @default_lang }
          next if missing.empty?

          origin_url = ensure_leading_slash(finalize_url(origin.doc.url, origin.doc))
          missing.each do |lang|
            # If origin is a post, create a synthetic rendered copy in missing language instead of a redirect.
            if origin.doc.is_a?(Jekyll::Document) && origin.doc.collection.label == 'posts'
              rel_origin = origin_url.sub(%r{^/}, '') # posts/doubt-science/
              dir = File.join(lang, File.dirname(rel_origin))
              name = 'index.html'
              target_url = ensure_leading_slash("/#{lang}/" + rel_origin)

              next if @site.pages.any? { |p| p.url == target_url }

              synthetic = Jekyll::PageWithoutAFile.new(@site, @site.source, dir, name)
              synthetic.data['layout'] = 'post'
              synthetic.data['lang'] = lang
              synthetic.data['original_language'] = origin.lang
              synthetic.data['title'] = origin.doc.data['title']
              synthetic.data['categories'] = origin.doc.data['categories']
              synthetic.data['tags'] = origin.doc.data['tags']
              synthetic.data['date'] = origin.doc.data['date']
              synthetic.data['original_slug'] = origin.doc.data['original_slug']
              synthetic.data['synthetic_translation'] = true
              synthetic.data['translation_disclaimer'] = {
                'should_render' => true,
                'reason' => 'synthetic_missing',
                'source_lang' => origin.lang,
                'target_lang' => lang,
                'origin_url' => origin_url,
                'provider' => nil,
                'translated_at' => nil
              }
              # Use origin raw content (markdown) so layout/post pipeline renders it.
              synthetic.content = origin.doc.content
              # Prevent indexing until real translation exists.
              synthetic.data['robots'] = 'noindex,follow'
              synthetic.data['sitemap'] = false
              @site.pages << synthetic
              log(:info, :SYNTHETIC_POST, "generated synthetic post copy lang=#{lang} origin_url=#{origin_url}")
            else
              redirect_target = "#{origin_url}?missing_lang=#{lang}"
              rel_origin = origin_url.sub(%r{^/}, '')
              dir = File.join(lang, File.dirname(rel_origin))
              name = 'index.html'
              next if @site.pages.any? { |p| p.url == "/#{lang}#{origin_url}" }
              page = Jekyll::PageWithoutAFile.new(@site, @site.source, dir, name)
              page.content = <<~HTML
                <!doctype html>
                <html lang="#{lang}">
                <head>
                  <meta charset="utf-8">
                  <title>Redirecting…</title>
                  <meta name="robots" content="noindex,follow">
                  <link rel="canonical" href="#{origin_url}">
                  <meta http-equiv="refresh" content="0; url=#{redirect_target}">
                  <script>window.location.replace(#{redirect_target.inspect});</script>
                </head>
                <body>
                  <p>Redirecting to available language… <a href="#{redirect_target}">Continue</a></p>
                </body>
                </html>
              HTML
              page.data['layout'] = nil
              page.data['sitemap'] = false
              page.data['redirect_from_lang'] = lang
              @site.pages << page
              log(:info, :MISSING_REDIRECT, "generated placeholder lang=#{lang} origin_url=#{origin_url}")
            end
          end
        end
      end

      def variant_timestamp(doc)
        explicit = doc.data['last_modified_at'] || doc.data['date']
        time = parse_time(explicit)
        return time if time

        File.mtime(doc.path)
      rescue StandardError
        Time.at(0)
      end

      def primary_sort_time(variant)
        parse_time(variant.doc.data['date']) || variant.mtime
      end

      def parse_time(value)
        case value
        when Time
          value
        when Date
          Time.new(value.year, value.month, value.day)
        when String
          Time.parse(value)
        else
          nil
        end
      rescue ArgumentError, TypeError
        nil
      end

      def truthy?(value)
        value == true || value.to_s.downcase == 'true'
      end

      def ensure_leading_slash(url)
        return nil if url.nil? || url.empty?
        url.start_with?('/') ? url : "/#{url}"
      end

      # Some URLs may still contain placeholder tokens like :title (when defaults/permalink not yet
      # substituted). We defensively substitute the :title token using the document's generated slug.
      def finalize_url(url, doc)
        return url if url.nil? || url.empty?
        return url unless url.include?(':')
        # Prefer the document's computed slug (from filename), not title.
        # This preserves language suffixes like "-en" and avoids drifting slugs from human-readable titles.
        raw_slug = if doc.respond_to?(:slug) && doc.slug
          doc.slug
        elsif doc.data['slug']
          doc.data['slug'].to_s
        else
          # Derive from basename, stripping leading date if present (YYYY-MM-DD-)
          base = doc.basename_without_ext.to_s
          base.sub(/^\d{4}-\d{1,2}-\d{1,2}-/, '')
        end
        slug = raw_slug.to_s.downcase.strip.gsub(/[^a-z0-9\-\s]/,'').gsub(/\s+/,'-')
        url.gsub(':title', slug)
      end

      def relative_path(doc)
        doc.relative_path || doc.path
      end

      def prune_fatal_docs
        return if @fatal_docs.empty?

        @fatal_docs.each do |doc|
          @site.posts.docs.delete(doc)
        end

        raise Jekyll::Errors::FatalException, 'translation validator encountered fatal errors'
      end

      def log(level, code, message)
        line = @logger.line(level, code, message)

        method = case level.to_sym
                 when :error
                   :error
                 when :warn
                   :warn
                 else
                   :info
                 end

        Jekyll.logger.public_send(method, line)
      end
    end
  end
end

Jekyll::Hooks.register :site, :post_read do |site|
  Jekyll::TranslationValidator::Plugin.run(site)
end
