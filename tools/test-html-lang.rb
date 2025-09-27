#!/usr/bin/env ruby
# Verify that localized output under /<lang>/ has matching <html lang="<lang>", and default pages have default lang.
require 'nokogiri'
SITE = File.expand_path('../_site', __dir__)
CONFIG = File.expand_path('../_config.yml', __dir__)
default_lang = 'zh-CN'
langs = %w[zh-CN en]
failures = []
Dir.glob(File.join(SITE,'**','index.html')).each do |f|
  rel = f.delete_prefix(SITE)
  html = File.read(f)
  # Skip known redirect placeholder or asset listing pages
  if html.include?('http-equiv="refresh"') || rel.start_with?('/assets/') || rel.start_with?('/en/assets/')
    next
  end
  doc = Nokogiri::HTML(html)
  node = doc.at_xpath('//html')
  next unless node
  actual = node['lang']
  # Determine expected language from path prefix
  expected = default_lang
  langs.each do |l|
    next if l == default_lang
    if rel.start_with?("/#{l}/")
      expected = l
      break
    end
  end
  normalized_actual = actual.to_s.downcase
  normalized_expected = expected.downcase
  # Allow en-us synonym for en
  if normalized_expected == 'en' && normalized_actual == 'en-us'
    next
  end
  if normalized_actual != normalized_expected
    failures << "#{f}: expected lang=#{expected} got=#{actual}"
  end
end

if failures.empty?
  puts '[html-lang-test] OK'
else
  warn '[html-lang-test] FAIL:'
  failures.each { |m| warn "  - #{m}" }
  exit 1
end
