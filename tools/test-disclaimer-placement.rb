#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'date'

ROOT = File.expand_path('..', __dir__)
POSTS_DIR = File.join(ROOT, '_posts')
SITE_DIR = File.join(ROOT, '_site')
DEFAULT_LANG = 'zh-CN'
FAILURES = []

unless Dir.exist?(SITE_DIR)
  warn '[disclaimer-test] _site not found. Run `bundle exec jekyll build` first.'
  exit 1
end

def parse_front_matter(path)
  content = File.read(path)
  return {} unless content.start_with?('---')

  parts = content.split(/^---\s*$\n/, 3)
  return {} if parts.size < 2

  front = parts[1]
  YAML.safe_load(front, permitted_classes: [Date, Time], aliases: true) || {}
rescue StandardError => e
  FAILURES << "#{path}: failed to parse front matter (#{e.message})"
  {}
end

def post_slug_from_filename(path)
  File.basename(path, '.md').sub(/^\d{4}-\d{2}-\d{2}-/, '')
end

def expected_build_path(lang, slug)
  segments = [SITE_DIR]
  segments << lang unless lang.nil? || lang == DEFAULT_LANG
  segments += %W[posts #{slug} index.html]
  File.join(*segments)
end

def ensure_disclaimer(path)
  html = File.read(path)
  matches = html.enum_for(:scan, /<aside[^>]*data-component="translation-disclaimer"[^>]*>[\s\S]*?<\/aside>/i)
               .map { Regexp.last_match }

  if matches.empty?
    FAILURES << "#{path}: missing translation disclaimer"
    return
  end

  if matches.size > 1
    FAILURES << "#{path}: multiple translation disclaimers present"
  end

  first_h2_index = html =~ /<h2\b/i
  matches.each do |match|
    aside_html = match[0]
    unless aside_html.include?('data-reason=') && aside_html.include?('data-source-lang=')
      FAILURES << "#{path}: disclaimer missing required data attributes"
    end

    next if first_h2_index.nil?

    if match.begin(0) > first_h2_index
      FAILURES << "#{path}: disclaimer appears after first <h2> heading"
    end
  end
end

Dir.glob(File.join(POSTS_DIR, '*.md')).each do |post_path|
  front = parse_front_matter(post_path)
  lang = front.fetch('lang', DEFAULT_LANG)
  translated_flag = front['translated'] == true
  original_lang = front['original_language']
  needs_disclaimer = translated_flag || (original_lang && original_lang != lang)
  next unless needs_disclaimer

  slug = post_slug_from_filename(post_path)
  built_path = expected_build_path(lang, slug)

  unless File.exist?(built_path)
    FAILURES << "#{built_path}: built HTML not found"
    next
  end

  ensure_disclaimer(built_path)
end

if FAILURES.empty?
  puts '[disclaimer-test] OK: translation disclaimers present and well-placed.'
  exit 0
else
  warn '[disclaimer-test] FAIL:'
  FAILURES.each { |msg| warn "  - #{msg}" }
  exit 1
end
