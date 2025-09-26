## frozen_string_literal: true

# A defensive wrapper to avoid passing arbitrary long text blobs into
# Jekyll's built-in `relative_url` filter (which will invoke Addressable::URI
# and raise when given invalid URI schemes). We only attempt to build a
# relative URL when the input looks like a site-internal path (starts with '/').
# Otherwise we return an empty string (or the original input if you prefer).

module Jekyll
  module SafeUrlFilter
    def safe_relative_url(input)
      return '' if input.nil?
      str = input.to_s.strip
      # Only treat as a path if it starts with '/'
      return '' unless str.start_with?('/')

      # Collapse any accidental whitespace/newlines inside
      str = str.gsub(/\s+/, ' ')
      # Basic sanity: disallow spaces in URL path segment we generate
      return '' if str.match?(/\s/)

      site = @context.registers[:site]
      base = site.config['baseurl'].to_s.rstrip
      if base.empty?
        str
      else
        # Ensure exactly one slash joins base and path
        (base + str).gsub(/\/+/, '/')
      end
    rescue => e
      Jekyll.logger.warn("SafeUrlFilter", "Failed to build safe URL for input: #{str.inspect} (#{e.class}: #{e.message})")
      ''
    end
  end
end

Liquid::Template.register_filter(Jekyll::SafeUrlFilter)
