## frozen_string_literal: true

module Jekyll
  module Filters
    module URLFilters
      if method_defined?(:relative_url) && !method_defined?(:_orig_relative_url_for_debug)
        alias_method :_orig_relative_url_for_debug, :relative_url

        def relative_url(input)
          begin
            str = input.to_s
            if str.size > 40 && !(str.start_with?('/') || str.include?('://'))
              page = @context.registers[:page] || {}
              page_path = page['path'] || page['url'] || 'unknown-page'
              # Try to find variable names in current scopes that reference this string
              var_hits = []
              begin
                @context.scopes.each do |scope|
                  scope.each do |k,v|
                    if v.is_a?(String) && v[0,60] == str[0,60]
                      var_hits << k unless var_hits.include?(k)
                    end
                  end
                end
              rescue => inner
                Jekyll.logger.warn('relative_url-debug', "scope scan failed: #{inner.class}: #{inner.message}")
              end
              Jekyll.logger.warn(
                'relative_url-input',
                "suspicious (len=#{str.size}) page=#{page_path} vars=#{var_hits.join(',')} snippet=#{str[0,80].gsub(/\s+/,' ')} ..."
              )
            end
            _orig_relative_url_for_debug(input)
          rescue => e
            snippet = input.to_s.strip.gsub(/\s+/, ' ')[0, 80]
            page = @context.registers[:page] || {}
            page_path = page['path'] || page['url'] || 'unknown-page'
            Jekyll.logger.warn(
              'relative_url-error',
              "rescued page=#{page_path}: #{snippet.inspect} (#{e.class}: #{e.message}) -> '#'"
            )
            '#'
          end
        end
      end
    end
  end
end
