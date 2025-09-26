require 'digest'
require 'yaml'
require 'fileutils'
require 'net/http'
require 'json'
require 'uri'

module Jekyll
  class TranslationProcessor
    attr_reader :site, :config

    def initialize(site_or_config)
      if site_or_config.respond_to?(:config)
        # It's a Jekyll::Site object
        @site = site_or_config
        @config = site_or_config.config['translation'] || {}
        @cache_dir = File.join(site_or_config.source, '_data', 'translations', 'posts')
        @metadata_dir = File.join(site_or_config.source, '_data', 'translations', 'metadata')
      else
        # It's a config hash (backward compatibility)
        @config = site_or_config['translation'] || {}
        @cache_dir = File.join('.', '_data', 'translations', 'posts')
        @metadata_dir = File.join('.', '_data', 'translations', 'metadata')
      end
      
      # Ensure cache directories exist
      FileUtils.mkdir_p(@cache_dir)
      FileUtils.mkdir_p(@metadata_dir)
    end

    # Main translation hook - matches contract specification
    def translate_content(content, source_lang, target_lang, provider_config)
      start_time = Time.now
      
      # Input validation
      raise ArgumentError, "Content must be a string" unless content.is_a?(String)
      raise ArgumentError, "Unsupported target language: #{target_lang}" unless %w[zh en].include?(target_lang)
      
      return skip_translation(content, start_time) if source_lang == target_lang
      
      # Generate content hash for caching
      content_hash = generate_content_hash(content)
      
      # Check cache first
      cached_result = check_cache(content_hash, provider_config['provider'] || @config['default_provider'])
      if cached_result
        cached_result['processing_time'] = Time.now - start_time
        return cached_result
      end
      
      # Perform translation
      begin
        translated_text = perform_translation(content, source_lang, target_lang, provider_config)
        
        result = {
          'translated_content' => translated_text,
          'provider_used' => provider_config['provider'] || @config['default_provider'],
          'token_count' => estimate_token_count(content + translated_text),
          'quality_score' => 0.9, # Default quality score - could be enhanced with actual quality assessment
          'cached' => false,
          'processing_time' => Time.now - start_time
        }
        
        # Cache the result
        cache_translation(content_hash, content, result)
        
        return result
        
      rescue => e
        Jekyll.logger.warn "Translation failed: #{e.message}"
        
        return {
          'translated_content' => content, # Fallback to original content
          'provider_used' => 'fallback',
          'token_count' => 0,
          'quality_score' => 0.0,
          'cached' => false,
          'processing_time' => Time.now - start_time,
          'error' => e.message
        }
      end
    end

    private

    def skip_translation(content, start_time)
      {
        'translated_content' => content,
        'provider_used' => 'none',
        'token_count' => 0,
        'quality_score' => 1.0,
        'cached' => false,
        'processing_time' => Time.now - start_time
      }
    end

    def generate_content_hash(content)
      Digest::SHA256.hexdigest(content.strip)
    end

    def check_cache(content_hash, provider)
      cache_file = File.join(@cache_dir, "#{content_hash}_#{provider}.yml")
      
      if File.exist?(cache_file)
        cached_data = YAML.load_file(cache_file)
        
        # Update last_used timestamp
        cached_data['last_used'] = Time.now.utc.iso8601
        File.write(cache_file, cached_data.to_yaml)
        
        return {
          'translated_content' => cached_data['translated_content'],
          'provider_used' => cached_data['provider'],
          'token_count' => cached_data['token_count'],
          'quality_score' => cached_data['quality_score'] || 0.9,
          'cached' => true,
          'processing_time' => 0.0
        }
      end
      
      nil
    end

    def cache_translation(content_hash, original_content, result)
      provider = result['provider_used']
      cache_file = File.join(@cache_dir, "#{content_hash}_#{provider}.yml")
      
      cache_data = {
        'source_hash' => content_hash,
        'source_content' => original_content,
        'translated_content' => result['translated_content'],
        'provider' => provider,
        'created_at' => Time.now.utc.iso8601,
        'last_used' => Time.now.utc.iso8601,
        'quality_score' => result['quality_score'],
        'token_count' => result['token_count']
      }
      
      File.write(cache_file, cache_data.to_yaml)
    end

    def perform_translation(content, source_lang, target_lang, provider_config)
      provider_name = provider_config['provider'] || @config['default_provider']
      provider_settings = @config.dig('providers', provider_name)
      
      unless provider_settings
        raise "Provider '#{provider_name}' not configured"
      end
      
      case provider_name
      when 'gemini'
        translate_with_gemini(content, source_lang, target_lang, provider_settings)
      when 'openai'
        translate_with_openai(content, source_lang, target_lang, provider_settings)
      when 'claude'
        translate_with_claude(content, source_lang, target_lang, provider_settings)
      else
        raise "Unsupported provider: #{provider_name}"
      end
    end

    def translate_with_gemini(content, source_lang, target_lang, settings)
      api_key = ENV[settings['api_key_env']]
      raise "Missing API key for Gemini" unless api_key
      
      uri = URI("https://generativelanguage.googleapis.com/v1beta/models/#{settings['model']}:generateContent?key=#{api_key}")
      
      prompt = build_translation_prompt(content, source_lang, target_lang)
      
      request_body = {
        contents: [{
          parts: [{
            text: prompt
          }]
        }],
        generationConfig: {
          maxOutputTokens: settings['max_tokens'],
          temperature: 0.1
        }
      }
      
      response = make_http_request(uri, request_body.to_json, {
        'Content-Type' => 'application/json'
      })
      
      result = JSON.parse(response.body)
      
      if response.code.to_i != 200
        raise "Gemini API error: #{result['error']['message'] rescue 'Unknown error'}"
      end
      
      translated_text = result.dig('candidates', 0, 'content', 'parts', 0, 'text')
      raise "No translation returned from Gemini" unless translated_text
      
      # Clean up the response (remove any markdown formatting if present)
      translated_text.gsub(/^```.*?\n|```$/, '').strip
    end

    def translate_with_openai(content, source_lang, target_lang, settings)
      # OpenAI implementation placeholder - would use GPT-4 API
      raise "OpenAI translation not yet implemented - use Gemini as primary provider"
    end

    def translate_with_claude(content, source_lang, target_lang, settings)
      # Claude implementation placeholder - would use Claude API
      raise "Claude translation not yet implemented - use Gemini as primary provider"
    end

    def build_translation_prompt(content, source_lang, target_lang)
      source_name = source_lang == 'zh-CN' ? 'Chinese' : 'English'
      target_name = target_lang == 'en' ? 'English' : 'Chinese'
      
      <<~PROMPT
        Please translate the following #{source_name} text to #{target_name}. 
        
        Important guidelines:
        1. Preserve all Markdown formatting exactly
        2. Keep code blocks, mathematical expressions, and LaTeX unchanged
        3. For mixed terms like "休谟问题(Hume's problem)", translate both parts appropriately
        4. Preserve existing English and Japanese text unless it's part of a Chinese context that needs translation
        5. Maintain the natural flow and meaning of the original text
        6. Keep technical terms and proper nouns consistent
        
        Text to translate:
        
        #{content}
        
        Provide only the translated text without any explanations or additional formatting.
      PROMPT
    end

    def make_http_request(uri, body, headers)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 30
      
      request = Net::HTTP::Post.new(uri.request_uri, headers)
      request.body = body
      
      http.request(request)
    end

    def estimate_token_count(text)
      # Rough token estimation: ~4 characters per token for mixed Chinese/English
      (text.length / 4.0).ceil
    end
  end
end