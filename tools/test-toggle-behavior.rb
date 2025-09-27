#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'set'

SITE_PATH = File.expand_path('../_site', __dir__)
FAILURES = []

unless Dir.exist?(SITE_PATH)
  warn "[toggle-test] _site not found at #{SITE_PATH}. Run `bundle exec jekyll build` first."
  exit 1
end

TOGGLE_SELECTOR = 'data-component="language-toggle"'

def html_files
  Dir.glob(File.join(SITE_PATH, '**/*.html'))
end

def analyze_file(path)
  html = File.read(path)
  toggles = html.scan(/<button[^>]*#{TOGGLE_SELECTOR}[^>]*>/i)
  return if toggles.empty?

  toggles.each do |button|
    data = {}
    button.scan(/data-([a-z0-9\-]+)="([^"]*)"/i) { |key, value| data[key] = value }

    unless data['original-slug'] && !data['original-slug'].empty?
      FAILURES << "#{path}: missing data-original-slug"
    end
    unless data['permalink-map'] && !data['permalink-map'].empty?
      FAILURES << "#{path}: missing data-permalink-map"
    end
    unless data['active-lang'] && data['default-lang']
      FAILURES << "#{path}: missing data-active-lang or data-default-lang"
    end
  end
end

html_files.each { |path| analyze_file(path) }

if FAILURES.empty?
  puts '[toggle-test] OK: language toggle buttons expose required data attributes.'
  exit 0
else
  warn '[toggle-test] FAIL:'
  FAILURES.each { |msg| warn "  - #{msg}" }
  exit 1
end
