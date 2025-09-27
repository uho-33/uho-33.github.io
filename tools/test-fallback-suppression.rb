#!/usr/bin/env ruby
# frozen_string_literal: true
# T047 ensure English build pages don't list zh-CN posts and vice versa in lists
SITE = File.expand_path('../_site', __dir__)
FAIL=[]
# simplistic heuristic: on /en/ homepage, look for known Chinese-only slug titles
CHINESE_SLUGS = Dir.glob(File.join(File.expand_path('../_posts', __dir__),'*.md')).filter_map do |p|
  fm = File.read(p).split(/^---\s*$\n/)[1] rescue nil
  next unless fm
  lang = fm[/\nlang:\s*(.*)$/,1]&.strip
  title = fm[/\ntitle:\s*(.*)$/,1]&.strip
  if lang == 'zh-CN' then title end
end.compact
home_en = File.join(SITE,'en','index.html')
if File.exist?(home_en)
 html = File.read(home_en)
 CHINESE_SLUGS.each do |t|
   if html.include?(t)
     FAIL << "English homepage contains Chinese post title #{t}"
   end
 end
end
home_zh = File.join(SITE,'index.html')
if File.exist?(home_zh)
 html = File.read(home_zh)
 # English titles (lang: en)
 EN_TITLES = Dir.glob(File.join(File.expand_path('../_posts', __dir__),'*.md')).filter_map do |p|
   fm = File.read(p).split(/^---\s*$\n/)[1] rescue nil
   next unless fm
   lang = fm[/\nlang:\s*(.*)$/,1]&.strip
   title = fm[/\ntitle:\s*(.*)$/,1]&.strip
   title if lang == 'en'
 end
 EN_TITLES.each do |t|
   if html.include?(t)
     FAIL << "Chinese homepage contains English post title #{t}"
   end
 end
end
if FAIL.empty?
  puts '[fallback-suppression-test] OK'
else
  warn '[fallback-suppression-test] FAIL:'
  FAIL.each{|m| warn "  - #{m}" }
  exit 1
end
