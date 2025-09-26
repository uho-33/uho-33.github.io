require 'strscan'

module Jekyll
  class ContentFilter
    # Detect Chinese content segments in mixed-language text
    # Returns array of segment hashes as specified in contract
    def self.detect_chinese_segments(content)
      return [] if content.nil? || content.empty?
      
      segments = []
      scanner = StringScanner.new(content)
      pos = 0
      
      while !scanner.eos?
        # Check for code blocks first (highest priority)
        if match = scanner.scan(/```[\s\S]*?```/m)
          segments << create_segment('code', match, pos, scanner.pos, true)
          pos = scanner.pos
          next
        end
        
        # Check for inline code
        if match = scanner.scan(/`[^`]+`/)
          segments << create_segment('code', match, pos, scanner.pos, true)
          pos = scanner.pos
          next
        end
        
        # Check for math expressions (LaTeX)
        if match = scanner.scan(/\$\$[\s\S]*?\$\$|\$[^$]+\$/)
          segments << create_segment('math', match, pos, scanner.pos, true)
          pos = scanner.pos
          next
        end
        
        # Check for mixed Chinese-English terms like '休谟问题(Hume's problem)'
        if match = scanner.scan(/[\u4e00-\u9fff]+[^\u4e00-\u9fff]*\([^)]*\)/u)
          segments << create_segment('chinese', match, pos, scanner.pos, false)
          pos = scanner.pos
          next
        end
        
        # Check for Chinese characters
        if match = scanner.scan(/[\u4e00-\u9fff]+/u)
          segments << create_segment('chinese', match, pos, scanner.pos, false)
          pos = scanner.pos
          next
        end
        
        # Check for Japanese characters (Hiragana, Katakana, Kanji in Japanese context)
        if match = scanner.scan(/[\u3040-\u309f\u30a0-\u30ff]+/u)
          segments << create_segment('other', match, pos, scanner.pos, true)
          pos = scanner.pos
          next
        end
        
        # Check for other content (English, punctuation, etc.)
        if match = scanner.scan(/[^\u4e00-\u9fff\u3040-\u309f\u30a0-\u30ff`$]+/u)
          # Skip pure whitespace segments
          unless match.strip.empty?
            segments << create_segment('other', match, pos, scanner.pos, true)
          end
          pos = scanner.pos
          next
        end
        
        # Advance by one character if no pattern matches
        scanner.getch
        pos = scanner.pos
      end
      
      # Merge adjacent segments of the same type
      merge_adjacent_segments(segments)
    end
    
    # Filter content by removing or preserving segments based on translation needs
    def self.filter_for_translation(content)
      segments = detect_chinese_segments(content)
      
      chinese_segments = segments.select { |seg| seg[:type] == 'chinese' && !seg[:preserve] }
      
      if chinese_segments.empty?
        return {
          needs_translation: false,
          translatable_content: '',
          segment_map: []
        }
      end
      
      {
        needs_translation: true,
        translatable_content: chinese_segments.map { |seg| seg[:content] }.join(' '),
        segment_map: segments
      }
    end
    
    # Reconstruct content with translated segments
    def self.apply_translation(original_content, translation_result, segment_map)
      return original_content unless translation_result && segment_map
      
      result = original_content.dup
      translated_segments = extract_translated_segments(translation_result, segment_map)
      
      # Replace Chinese segments with translations (in reverse order to maintain positions)
      segment_map.reverse.each_with_index do |segment, index|
        if segment[:type] == 'chinese' && !segment[:preserve]
          translated_text = translated_segments[segment_map.length - 1 - index]
          if translated_text
            result[segment[:start_pos]...segment[:end_pos]] = translated_text
          end
        end
      end
      
      result
    end
    
    private
    
    def self.create_segment(type, content, start_pos, end_pos, preserve)
      {
        type: type,
        content: content,
        start_pos: start_pos,
        end_pos: end_pos,
        preserve: preserve
      }
    end
    
    def self.merge_adjacent_segments(segments)
      return segments if segments.length <= 1
      
      merged = [segments.first]
      
      segments[1..-1].each do |segment|
        last_segment = merged.last
        
        # Merge if same type and preserve status, and adjacent positions
        if last_segment[:type] == segment[:type] && 
           last_segment[:preserve] == segment[:preserve] &&
           last_segment[:end_pos] == segment[:start_pos]
          
          merged[-1] = {
            type: last_segment[:type],
            content: last_segment[:content] + segment[:content],
            start_pos: last_segment[:start_pos],
            end_pos: segment[:end_pos],
            preserve: last_segment[:preserve]
          }
        else
          merged << segment
        end
      end
      
      merged
    end
    
    def self.extract_translated_segments(translation_result, segment_map)
      # This is a simplified extraction - in practice, this would need
      # more sophisticated parsing to match translated segments back to originals
      chinese_segments = segment_map.select { |seg| seg[:type] == 'chinese' && !seg[:preserve] }
      
      if chinese_segments.length == 1
        [translation_result]
      else
        # For multiple segments, split the translation result
        # This is a basic implementation - could be enhanced with better parsing
        translation_result.split(/[。！？.!?]/).map(&:strip).reject(&:empty?)
      end
    end
  end
  
  # Jekyll hook to integrate with Polyglot
  Jekyll::Hooks.register :posts, :pre_render do |post, payload|
    begin
      site = payload['site']
      # Ensure we have a site object with config
      next unless site && site.respond_to?(:config)

  config_obj = site.respond_to?(:config) ? site.config : {}
  translation_cfg = config_obj.is_a?(Hash) ? (config_obj['translation'] || {}) : {}
  enabled = translation_cfg['enabled'] == true
  # Skip entirely if translation feature disabled
  next unless enabled

      # Only process during English variant generation (Polyglot sets either site.active_lang or config value)
      active_lang = (site.respond_to?(:active_lang) ? site.active_lang : site.config['active_lang'])
      Jekyll.logger.debug "ContentFilter:", "active_lang=#{active_lang.inspect} post_lang=#{post.data['lang'].inspect}"
      next unless active_lang == 'en'

      # Skip if original post already in English
      next if post.data['lang'] == 'en'

      # Skip if empty content
      next unless post.content && !post.content.empty?

      # Determine provider (fall back to gemini if missing)
      provider = translation_cfg['default_provider'] || 'gemini'

      processor = TranslationProcessor.new(site)

      filter_result = ContentFilter.filter_for_translation(post.content)
      if filter_result[:needs_translation]
        translation_result = processor.translate_content(
          filter_result[:translatable_content],
          'zh-CN',
          'en',
          { 'provider' => provider }
        )

        if translation_result && translation_result['translated_content']
          post.content = ContentFilter.apply_translation(
            post.content,
            translation_result['translated_content'],
            filter_result[:segment_map]
          )

            post.data['translated'] = true
            post.data['translation_provider'] = translation_result['provider_used']
            post.data['translation_quality'] = translation_result['quality_score']
        end
      end
    rescue StandardError => e
      Jekyll.logger.error "ContentFilter:", "Error processing #{post.path}: #{e.message}"
      Jekyll.logger.debug "ContentFilter:", e.backtrace&.first(5)&.join(" | ")
    end
  end
end