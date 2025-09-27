#!/usr/bin/env ruby
# frozen_string_literal: true
# T046 - verify hreflang tags match data-permalink-map
require 'nokogiri'
require 'json'
SITE = File.expand_path('../_site', __dir__)
FAIL=[]
Dir.glob(File.join(SITE,'**/index.html')).each do |f|
  html = File.read(f)
  doc = Nokogiri::HTML(html)
  toggle = doc.at_css('button[data-component="language-toggle"]')
  next unless toggle
  raw = toggle['data-permalink-map']
  synthetic = toggle['data-map-synthetic'] == 'true'
  # Skip purely synthetic maps (pages without validator-provided permalink_lang)
  next if synthetic
  map = {}
  if raw && raw.strip.start_with?('{')
    begin
      json = raw.gsub('&quot;','"').gsub('&#39;','"')
      map = JSON.parse(json)
    rescue => e
      FAIL << "#{f}: bad permalink map json (#{e.message})"
      next
    end
  else
    next
  end
  hreflangs = doc.css('link[rel="alternate"]').map{|l| [l['hreflang'], l['href']]}.to_h
  map.each do |lang,url|
    l = lang.downcase
    unless hreflangs[l]
      FAIL << "#{f}: missing hreflang #{lang}"
    end
  end
end
if FAIL.empty?
  puts '[hreflang-test] OK'
else
  warn '[hreflang-test] FAIL:'
  FAIL.each{|m| warn "  - #{m}" }
  exit 1
end
