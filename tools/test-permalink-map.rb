#!/usr/bin/env ruby
# frozen_string_literal: true
# Validates that each built page with a language toggle exposes a consistent permalink_lang map
# T045
require 'json'
SITE = File.expand_path('../_site', __dir__)
FAIL=[]
Dir.glob(File.join(SITE,'**/index.html')).each do |f|
  html = File.read(f)
  next unless html.include?('data-permalink-map=')
  html.scan(/data-permalink-map="([^"]+)"/).each do |raw|
    json = raw.first.gsub('&quot;','"')
    begin
      map = JSON.parse(json)
      if map.values.any?{|v| !v.start_with?('/')}
        FAIL << "#{f}: non absolute path in map"
      end
      langs = map.keys
      if langs.uniq.size != langs.size
        FAIL << "#{f}: duplicate lang keys"
      end
    rescue => e
      FAIL << "#{f}: parse error #{e.message}"
    end
  end
end
if FAIL.empty?
  puts '[permalink-map-test] OK'
else
  warn '[permalink-map-test] FAIL:'
  FAIL.each{ |m| warn "  - #{m}" }
  exit 1
end
