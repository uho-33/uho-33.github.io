require 'net/http'
require 'json'
require 'uri'

module Jekyll
  class GeminiTranslator
    API_ENDPOINT = 'https://generativelanguage.googleapis.com/v1beta/models'
    
    attr_reader :config, :api_key, :model

    def initialize(config = {})
      @config = config
      @api_key = ENV[config['api_key_env']] || ENV['GEMINI_API_KEY']
      @model = config['model'] || 'gemini-2.0-flash-exp'
      @max_tokens = config['max_tokens'] || 4096
      @rate_limit = config['rate_limit'] || 15  # requests per minute
      
      validate_configuration
    end

    # Main translation method
    def translate(text, source_lang = 'zh-CN', target_lang = 'en', options = {})
      validate_inputs(text, source_lang, target_lang)
      
      prompt = build_translation_prompt(text, source_lang, target_lang, options)
      
      begin
        response = make_api_request(prompt, options)
        parse_response(response)
      rescue => e
        Jekyll.logger.error "Gemini translation failed: #{e.message}"
        handle_error(e, text)
      end
    end

    # Batch translation for multiple texts
    def translate_batch(texts, source_lang = 'zh-CN', target_lang = 'en', options = {})
      return [] if texts.empty?
      
      results = []
      
      texts.each_with_index do |text, index|
        Jekyll.logger.info "Translating batch item #{index + 1}/#{texts.length}"
        
        result = translate(text, source_lang, target_lang, options)
        results << result
        
        # Rate limiting
        sleep_time = 60.0 / @rate_limit
        sleep(sleep_time) if index < texts.length - 1
      end
      
      results
    end

    # Check API connectivity and quota
    def health_check
      test_text = "测试"
      
      begin
        result = translate(test_text, 'zh-CN', 'en', { test_mode: true })
        
        if result[:success] && result[:translated_text]
          {
            status: 'healthy',
            message: 'Gemini API is accessible and functional',
            test_translation: result[:translated_text],
            model: @model
          }
        else
          {
            status: 'error',
            message: 'API call succeeded but translation failed',
            error: result[:error]
          }
        end
      rescue => e
        {
          status: 'error',
          message: 'Cannot connect to Gemini API',
          error: e.message
        }
      end
    end

    private

    def validate_configuration
      unless @api_key
        raise ArgumentError, "Gemini API key not found. Set GEMINI_API_KEY environment variable or configure api_key_env"
      end
      
      if @api_key.length < 20
        raise ArgumentError, "Invalid Gemini API key format"
      end
    end

    def validate_inputs(text, source_lang, target_lang)
      raise ArgumentError, "Text cannot be empty" if text.nil? || text.strip.empty?
      raise ArgumentError, "Unsupported source language: #{source_lang}" unless %w[zh-CN en].include?(source_lang)
      raise ArgumentError, "Unsupported target language: #{target_lang}" unless %w[zh-CN en].include?(target_lang)
      
      if source_lang == target_lang
        raise ArgumentError, "Source and target languages cannot be the same"
      end
    end

    def build_translation_prompt(text, source_lang, target_lang, options = {})
      source_name = language_name(source_lang)
      target_name = language_name(target_lang)
      
      # Base translation prompt
      prompt = <<~PROMPT
        Please translate the following #{source_name} text to #{target_name}.
        
        CRITICAL INSTRUCTIONS:
        1. Preserve ALL Markdown formatting exactly (headers, links, lists, etc.)
        2. Keep code blocks (```code```) completely unchanged
        3. Keep mathematical expressions ($math$ and $$math$$) unchanged
        4. For mixed terms like "休谟问题(Hume's problem)", translate both the Chinese and English parts appropriately
        5. Preserve existing English and Japanese text UNLESS it's part of a Chinese context requiring translation
        6. Maintain natural flow and academic tone
        7. Keep technical terms consistent
        8. Preserve line breaks and paragraph structure
        
        IMPORTANT: Provide ONLY the translated text. Do not add explanations, notes, or additional formatting.
      PROMPT
      
      # Add context-specific instructions
      if options[:preserve_code_comments]
        prompt += "\n9. Translate comments in code blocks if they are in #{source_name}"
      end
      
      if options[:academic_tone]
        prompt += "\n10. Use formal academic language appropriate for scholarly writing"
      end
      
      prompt += "\n\nText to translate:\n\n#{text}"
      
      prompt
    end

    def make_api_request(prompt, options = {})
      uri = build_api_uri
      request_body = build_request_body(prompt, options)
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = options[:timeout] || 30
      http.open_timeout = 10
      
      request = Net::HTTP::Post.new(uri.request_uri)
      request['Content-Type'] = 'application/json'
      request.body = request_body.to_json
      
      Jekyll.logger.debug "Making Gemini API request to: #{uri}"
      
      response = http.request(request)
      
      unless response.code.to_i == 200
        error_message = extract_error_message(response)
        raise "API request failed (#{response.code}): #{error_message}"
      end
      
      response
    end

    def build_api_uri
      URI("#{API_ENDPOINT}/#{@model}:generateContent?key=#{@api_key}")
    end

    def build_request_body(prompt, options = {})
      {
        contents: [{
          parts: [{
            text: prompt
          }]
        }],
        generationConfig: {
          maxOutputTokens: @max_tokens,
          temperature: options[:temperature] || 0.1,
          topP: options[:top_p] || 0.8,
          topK: options[:top_k] || 40
        },
        safetySettings: [
          {
            category: "HARM_CATEGORY_HARASSMENT",
            threshold: "BLOCK_MEDIUM_AND_ABOVE"
          },
          {
            category: "HARM_CATEGORY_HATE_SPEECH", 
            threshold: "BLOCK_MEDIUM_AND_ABOVE"
          }
        ]
      }
    end

    def parse_response(response)
      result = JSON.parse(response.body)
      
      # Check for API-level errors
      if result['error']
        raise "Gemini API error: #{result['error']['message']}"
      end
      
      # Extract translated text
      candidates = result['candidates']
      if candidates.nil? || candidates.empty?
        raise "No translation candidates returned"
      end
      
      candidate = candidates.first
      if candidate['finishReason'] && candidate['finishReason'] != 'STOP'
        Jekyll.logger.warn "Translation may be incomplete: #{candidate['finishReason']}"
      end
      
      content = candidate.dig('content', 'parts', 0, 'text')
      unless content
        raise "No translation text found in response"
      end
      
      # Clean up the response
      translated_text = clean_translation_output(content)
      
      {
        success: true,
        translated_text: translated_text,
        model: @model,
        finish_reason: candidate['finishReason'],
        usage: extract_usage_info(result)
      }
    end

    def clean_translation_output(text)
      # Remove any markdown code block wrapping if present
      cleaned = text.gsub(/^```[a-z]*\n?/, '').gsub(/\n?```$/, '')
      
      # Remove any leading/trailing explanation text that might have been added
      cleaned = cleaned.gsub(/^(Here's the translation|Translation:|Translated text):\s*/i, '')
      cleaned = cleaned.gsub(/\s*(That's the translation|Translation complete)\.?\s*$/i, '')
      
      # Normalize whitespace but preserve intentional line breaks
      cleaned.strip
    end

    def extract_usage_info(result)
      usage = result['usageMetadata'] || {}
      {
        prompt_tokens: usage['promptTokenCount'] || 0,
        completion_tokens: usage['candidatesTokenCount'] || 0,
        total_tokens: usage['totalTokenCount'] || 0
      }
    end

    def extract_error_message(response)
      begin
        error_data = JSON.parse(response.body)
        error_data.dig('error', 'message') || error_data['error'] || 'Unknown error'
      rescue JSON::ParserError
        response.body || 'Unknown error'
      end
    end

    def handle_error(error, original_text)
      error_message = case error
      when Net::TimeoutError
        "Request timeout - Gemini API is taking too long to respond"
      when Net::HTTPError
        "Network error - Unable to connect to Gemini API"
      when JSON::ParserError
        "Invalid response format from Gemini API"
      else
        error.message
      end
      
      {
        success: false,
        error: error_message,
        fallback_text: original_text,
        model: @model
      }
    end

    def language_name(code)
      case code
      when 'zh-CN' then 'Chinese'
      when 'en' then 'English'
      else code
      end
    end
  end
  
  # Jekyll integration hook
  Jekyll::Hooks.register :site, :after_init do |site|
    translation_config = site.config.dig('translation', 'providers', 'gemini')
    
    if translation_config && site.config.dig('translation', 'enabled')
      begin
        gemini_client = GeminiTranslator.new(translation_config)
        site.config['gemini_translator'] = gemini_client
        
        # Perform health check if enabled
        if ENV['JEKYLL_TRANSLATION_HEALTH_CHECK'] == 'true'
          health = gemini_client.health_check
          Jekyll.logger.info "Gemini API Health: #{health[:status]} - #{health[:message]}"
        end
        
      rescue => e
        Jekyll.logger.error "Failed to initialize Gemini translator: #{e.message}"
        # Don't fail the build - graceful degradation
      end
    end
  end
end