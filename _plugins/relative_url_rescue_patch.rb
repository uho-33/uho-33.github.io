## frozen_string_literal: true

# Temporary resilience patch: prevent the build from aborting when an invalid
# string (e.g. a long paragraph of post content) is accidentally piped into
# the `relative_url` filter. We wrap the underlying Jekyll helper and fall back
# to a harmless '#'. A warning is logged so we can later trace and correct the
# source template.

module Jekyll
  module Filters
    module URLFilters
      if method_defined?(:compute_relative_url)
        alias_method :_orig_compute_relative_url, :compute_relative_url

        def compute_relative_url(input)
          # Debug instrumentation: log unusual inputs (non-path, non-URL, long plain text)
            begin
              str = input.to_s
              if str.size > 40 && !(str.start_with?('/') || str.include?('://'))
                Jekyll.logger.warn("relative_url-debug", "suspicious input (len=#{str.size}): #{str[0,80].gsub(/\s+/,' ')} ...")
              end
            rescue => e
              Jekyll.logger.warn("relative_url-debug", "failed to inspect input: #{e.class}: #{e.message}")
            end
          _orig_compute_relative_url(input)
        rescue => e
          snippet = input.to_s.strip.gsub(/\s+/, ' ')[0, 80]
          Jekyll.logger.warn("relative_url", "rescued invalid input: #{snippet.inspect} (#{e.class}: #{e.message}) -> '#'")
          '#'
        end
      end
    end
  end
end
