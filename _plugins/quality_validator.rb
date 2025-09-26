module Jekyll
  class QualityValidator
    attr_reader :config, :validation_rules
    
    def initialize(config)
      @config = config
      @translation_config = config['translation'] || {}
      @validation_rules = setup_validation_rules
      @error_recovery = ErrorRecovery.new(config)
    end
    
    # Validate translation quality and attempt recovery if needed
    def validate_and_recover(original_text, translated_text, source_lang, target_lang)
      validation_results = []
      recovery_actions = []
      
      # Run all validation checks
      @validation_rules.each do |rule_name, rule|
        result = rule[:validator].call(original_text, translated_text, source_lang, target_lang)
        validation_results << {
          rule: rule_name,
          passed: result[:passed],
          score: result[:score],
          issues: result[:issues] || [],
          severity: rule[:severity]
        }
      end
      
      # Calculate overall quality score
      overall_score = calculate_overall_score(validation_results)
      
      # Determine if recovery is needed
      critical_failures = validation_results.select { |r| !r[:passed] && r[:severity] == :critical }
      warning_failures = validation_results.select { |r| !r[:passed] && r[:severity] == :warning }
      
      # Attempt recovery for critical failures
      recovered_text = translated_text
      if critical_failures.any?
        Jekyll.logger.warn "QualityValidator:", "Critical quality issues detected, attempting recovery"
        
        recovery_result = @error_recovery.attempt_recovery(
          original_text, 
          translated_text, 
          critical_failures,
          source_lang,
          target_lang
        )
        
        if recovery_result[:success]
          recovered_text = recovery_result[:content]
          recovery_actions = recovery_result[:actions]
          Jekyll.logger.info "QualityValidator:", "Recovery successful"
        else
          Jekyll.logger.error "QualityValidator:", "Recovery failed: #{recovery_result[:error]}"
        end
      end
      
      {
        success: critical_failures.empty? || recovery_actions.any?,
        content: recovered_text,
        quality_score: overall_score,
        validation_results: validation_results,
        recovery_actions: recovery_actions,
        needs_human_review: overall_score < 0.7 || critical_failures.any?
      }
    end
    
    private
    
    def setup_validation_rules
      {
        length_consistency: {
          validator: method(:validate_length_consistency),
          severity: :warning,
          weight: 0.2
        },
        structure_preservation: {
          validator: method(:validate_structure_preservation),
          severity: :critical,
          weight: 0.3
        },
        chinese_retention: {
          validator: method(:validate_chinese_retention),
          severity: :critical,
          weight: 0.3
        },
        format_preservation: {
          validator: method(:validate_format_preservation),
          severity: :critical,
          weight: 0.2
        }
      }
    end
    
    # Validate that translation length is reasonable
    def validate_length_consistency(original, translated, source_lang, target_lang)
      orig_length = original.length
      trans_length = translated.length
      
      # Allow for 50% variation in length
      ratio = trans_length.to_f / orig_length
      acceptable_range = 0.5..2.0
      
      passed = acceptable_range.include?(ratio)
      score = passed ? 1.0 : [0.0, 1.0 - (ratio - 1.0).abs].max
      
      issues = []
      unless passed
        if ratio < 0.5
          issues << "Translation significantly shorter than original (#{(ratio * 100).round(1)}%)"
        elsif ratio > 2.0
          issues << "Translation significantly longer than original (#{(ratio * 100).round(1)}%)"
        end
      end
      
      { passed: passed, score: score, issues: issues }
    end
    
    # Validate that markdown/HTML structure is preserved
    def validate_structure_preservation(original, translated, source_lang, target_lang)
      issues = []
      
      # Check markdown headers
      orig_headers = original.scan(/^#+\s/)
      trans_headers = translated.scan(/^#+\s/)
      
      if orig_headers.size != trans_headers.size
        issues << "Header count mismatch: #{orig_headers.size} vs #{trans_headers.size}"
      end
      
      # Check markdown links
      orig_links = original.scan(/\[([^\]]*)\]\(([^)]*)\)/)
      trans_links = translated.scan(/\[([^\]]*)\]\(([^)]*)\)/)
      
      if orig_links.size != trans_links.size
        issues << "Link count mismatch: #{orig_links.size} vs #{trans_links.size}"
      end
      
      # Check code blocks
      orig_code_blocks = original.scan(/```[\s\S]*?```/)
      trans_code_blocks = translated.scan(/```[\s\S]*?```/)
      
      if orig_code_blocks.size != trans_code_blocks.size
        issues << "Code block count mismatch: #{orig_code_blocks.size} vs #{trans_code_blocks.size}"
      end
      
      # Check inline code
      orig_inline_code = original.scan(/`[^`]+`/)
      trans_inline_code = translated.scan(/`[^`]+`/)
      
      if orig_inline_code.size != trans_inline_code.size
        issues << "Inline code count mismatch: #{orig_inline_code.size} vs #{trans_inline_code.size}"
      end
      
      passed = issues.empty?
      score = passed ? 1.0 : [0.0, 1.0 - (issues.size * 0.2)].max
      
      { passed: passed, score: score, issues: issues }
    end
    
    # Validate that Chinese terms in parentheses are preserved
    def validate_chinese_retention(original, translated, source_lang, target_lang)
      issues = []
      
      # Find Chinese terms in parentheses like "休谟问题(Hume's problem)"
      chinese_in_parens = original.scan(/[\u4e00-\u9fff]+\([^)]*\)/)
      
      chinese_in_parens.each do |term|
        unless translated.include?(term)
          issues << "Chinese term in parentheses not preserved: #{term}"
        end
      end
      
      # Find standalone Chinese phrases that should be preserved
      preserved_chinese = original.scan(/[\u4e00-\u9fff]{2,}/)
      
      preserved_chinese.each do |phrase|
        # Allow some flexibility - check if any part of the phrase is preserved
        if phrase.length > 4 && !translated.include?(phrase[0..2])
          issues << "Important Chinese phrase may be lost: #{phrase}"
        end
      end
      
      passed = issues.empty?
      score = passed ? 1.0 : [0.0, 1.0 - (issues.size * 0.3)].max
      
      { passed: passed, score: score, issues: issues }
    end
    
    # Validate that formatting (bold, italic, etc.) is preserved
    def validate_format_preservation(original, translated, source_lang, target_lang)
      issues = []
      
      # Check bold formatting
      orig_bold = original.scan(/\*\*[^*]+\*\*/)
      trans_bold = translated.scan(/\*\*[^*]+\*\*/)
      
      if orig_bold.size != trans_bold.size
        issues << "Bold formatting count mismatch: #{orig_bold.size} vs #{trans_bold.size}"
      end
      
      # Check italic formatting
      orig_italic = original.scan(/\*[^*]+\*/)
      trans_italic = translated.scan(/\*[^*]+\*/)
      
      if orig_italic.size != trans_italic.size
        issues << "Italic formatting count mismatch: #{orig_italic.size} vs #{trans_italic.size}"
      end
      
      # Check line breaks
      orig_breaks = original.count("\n")
      trans_breaks = translated.count("\n")
      
      if (orig_breaks - trans_breaks).abs > orig_breaks * 0.3
        issues << "Line break structure significantly changed"
      end
      
      passed = issues.empty?
      score = passed ? 1.0 : [0.0, 1.0 - (issues.size * 0.25)].max
      
      { passed: passed, score: score, issues: issues }
    end
    
    def calculate_overall_score(validation_results)
      weighted_scores = validation_results.map do |result|
        rule_config = @validation_rules[result[:rule]]
        result[:score] * rule_config[:weight]
      end
      
      weighted_scores.sum
    end
    
    # Error recovery strategies
    class ErrorRecovery
      def initialize(config)
        @config = config
        @translation_processor = TranslationProcessor.new(config)
      end
      
      def attempt_recovery(original_text, failed_translation, failures, source_lang, target_lang)
        recovery_actions = []
        
        # Strategy 1: Re-translate with different provider
        if has_alternative_provider?
          Jekyll.logger.info "ErrorRecovery:", "Attempting recovery with alternative provider"
          
          result = retry_with_alternative_provider(original_text, source_lang, target_lang)
          if result[:success]
            return {
              success: true,
              content: result[:content],
              actions: ['alternative_provider_retry']
            }
          end
        end
        
        # Strategy 2: Segment-based recovery
        Jekyll.logger.info "ErrorRecovery:", "Attempting segment-based recovery"
        
        segment_result = attempt_segment_recovery(original_text, failed_translation, source_lang, target_lang)
        if segment_result[:success]
          return {
            success: true,
            content: segment_result[:content],
            actions: ['segment_recovery']
          }
        end
        
        # Strategy 3: Conservative fallback
        Jekyll.logger.info "ErrorRecovery:", "Using conservative fallback"
        
        conservative_result = create_conservative_translation(original_text, failed_translation)
        return {
          success: true,
          content: conservative_result,
          actions: ['conservative_fallback']
        }
      end
      
      private
      
      def has_alternative_provider?
        providers = @config.dig('translation', 'providers') || {}
        providers.keys.size > 1
      end
      
      def retry_with_alternative_provider(text, source_lang, target_lang)
        @translation_processor.translate_content(text, source_lang, target_lang)
      end
      
      def attempt_segment_recovery(original_text, failed_translation, source_lang, target_lang)
        # Split into paragraphs and translate each separately
        paragraphs = original_text.split(/\n\s*\n/)
        recovered_paragraphs = []
        
        paragraphs.each do |paragraph|
          result = @translation_processor.translate_content(paragraph.strip, source_lang, target_lang)
          if result[:success]
            recovered_paragraphs << result[:content]
          else
            # Use original if translation fails
            recovered_paragraphs << paragraph
          end
        end
        
        {
          success: true,
          content: recovered_paragraphs.join("\n\n")
        }
      end
      
      def create_conservative_translation(original_text, failed_translation)
        # Return original with a translation note
        "#{original_text}\n\n*[Translation Note: This content could not be automatically translated. Please refer to the original Chinese version.]*"
      end
    end
  end
end