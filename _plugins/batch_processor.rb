require 'fileutils'

module Jekyll
  class BatchProcessor
    attr_reader :site, :config
    
    def initialize(site)
      @site = site
      @config = site.config
      @translation_config = @config['translation'] || {}
      @cache_manager = TranslationCacheManager.new(@config)
      @providers = setup_providers
    end
    
    # Process all posts for batch translation
    def process_all_posts
      Jekyll.logger.info "BatchProcessor:", "Starting batch translation process"
      
      stats = {
        processed: 0,
        translated: 0,
        cached: 0,
        skipped: 0,
        errors: 0
      }
      
      # Get all posts that need translation
      posts_to_process = find_posts_needing_translation
      
      Jekyll.logger.info "BatchProcessor:", "Found #{posts_to_process.size} posts to process"
      
      posts_to_process.each_with_index do |post, index|
        begin
          result = process_single_post(post)
          update_stats(stats, result)
          
          if (index + 1) % 10 == 0
            Jekyll.logger.info "BatchProcessor:", "Processed #{index + 1}/#{posts_to_process.size} posts"
          end
          
          # Rate limiting between posts
          sleep(@translation_config.dig('rate_limit', 'delay_between_posts') || 0.5)
          
        rescue StandardError => e
          Jekyll.logger.error "BatchProcessor:", "Error processing #{post.path}: #{e.message}"
          stats[:errors] += 1
        end
      end
      
      log_final_stats(stats)
      stats
    end
    
    # Process a single post for translation
    def process_single_post(post)
      stats[:processed] += 1
      
      # Check if post needs translation
      unless needs_translation?(post)
        return { status: 'skipped', reason: 'no_chinese_content' }
      end
      
      # Check cache first
      content_hash = generate_content_hash(post.content)
      cached_translation = @cache_manager.get_cached_translation(
        post.path, 
        content_hash, 
        'zh-CN', 
        'en'
      )
      
      if cached_translation
        create_english_post(post, cached_translation, 'cached')
        return { status: 'cached' }
      end
      
      # Perform translation
      translation_result = translate_post_content(post)
      
      if translation_result[:success]
        # Cache the result
        @cache_manager.store_translation(
          post.path,
          content_hash,
          'zh-CN',
          'en',
          translation_result[:content],
          translation_result[:provider]
        )
        
        # Create English post file
        create_english_post(post, translation_result[:content], translation_result[:provider])
        return { status: 'translated', provider: translation_result[:provider] }
      else
        Jekyll.logger.error "BatchProcessor:", "Failed to translate #{post.path}: #{translation_result[:error]}"
        return { status: 'error', error: translation_result[:error] }
      end
    end
    
    # Check if post needs English translation
    def needs_translation?(post)
      begin
        # Skip if already in English
        return false if post.data['lang'] == 'en'
        
        # Skip if post content is nil or empty
        return false unless post.content && !post.content.empty?
        
        # Check if Chinese content is present
        chinese_segments = ContentFilter.detect_chinese_segments(post.content)
        chinese_segments.any? { |segment| segment[:type] == 'chinese' }
      rescue => e
        Jekyll.logger.error "BatchProcessor:", "Error checking translation need for #{post.path}: #{e.message}"
        false
      end
    end
    
    # Create English version of post
    def create_english_post(original_post, translated_content, provider)
      # Determine English post path
      english_post_path = generate_english_post_path(original_post.path)
      
      # Create directory if it doesn't exist
      FileUtils.mkdir_p(File.dirname(english_post_path))
      
      # Generate English frontmatter
      english_frontmatter = generate_english_frontmatter(original_post, provider)
      
      # Combine frontmatter and content
      full_content = "#{english_frontmatter}\n#{translated_content}"
      
      # Write English post file
      File.write(english_post_path, full_content)
      
      Jekyll.logger.info "BatchProcessor:", "Created English post: #{english_post_path}"
    end
    
    # Generate path for English post
    def generate_english_post_path(original_path)
      # Convert _posts/2024-01-01-title.md to _posts/en/2024-01-01-title.md
      base_name = File.basename(original_path)
      posts_dir = File.dirname(original_path)
      File.join(posts_dir, 'en', base_name)
    end
    
    # Generate English frontmatter
    def generate_english_frontmatter(original_post, provider)
      frontmatter = original_post.data.dup
      
      # Set language and translation metadata
      frontmatter['lang'] = 'en'
      frontmatter['original_language'] = original_post.data['lang'] || 'zh-CN'
      frontmatter['translation_provider'] = provider
      frontmatter['translated_at'] = Time.now.iso8601
      
      # Translate title if it contains Chinese
      begin
        if frontmatter['title'] && !frontmatter['title'].empty? &&
           ContentFilter.detect_chinese_segments(frontmatter['title']).any?
          title_translation = translate_text(frontmatter['title'])
          frontmatter['title'] = title_translation if title_translation
        end
      rescue => e
        Jekyll.logger.error "BatchProcessor:", "Error translating title: #{e.message}"
      end
      
      # Translate description if it exists and contains Chinese
      begin
        if frontmatter['description'] && !frontmatter['description'].empty? &&
           ContentFilter.detect_chinese_segments(frontmatter['description']).any?
          desc_translation = translate_text(frontmatter['description'])
          frontmatter['description'] = desc_translation if desc_translation
        end
      rescue => e
        Jekyll.logger.error "BatchProcessor:", "Error translating description: #{e.message}"
      end
      
      "---\n#{frontmatter.to_yaml.gsub(/^---\n/, '')}---"
    end
    
    private
    
    def find_posts_needing_translation
      @site.posts.docs.select do |post|
        begin
          # Only process posts that are not already English and contain Chinese content
          !post.data['lang']&.start_with?('en') && 
          post.content && !post.content.empty? &&
          ContentFilter.detect_chinese_segments(post.content).any? { |s| s[:type] == 'chinese' }
        rescue => e
          Jekyll.logger.error "BatchProcessor:", "Error checking post #{post.path}: #{e.message}"
          false
        end
      end
    end
    
    def translate_post_content(post)
      # Use the same translation logic as TranslationProcessor
      processor = TranslationProcessor.new(@site)
      processor.translate_content(post.content, 'zh-CN', 'en')
    end
    
    def translate_text(text)
      processor = TranslationProcessor.new(@site)
      result = processor.translate_content(text, 'zh-CN', 'en')
      result[:success] ? result[:content] : nil
    end
    
    def generate_content_hash(content)
      Digest::SHA256.hexdigest(content)[0...16]
    end
    
    def setup_providers
      @translation_config['providers'] || {}
    end
    
    def update_stats(stats, result)
      case result[:status]
      when 'translated'
        stats[:translated] += 1
      when 'cached'
        stats[:cached] += 1
      when 'skipped'
        stats[:skipped] += 1
      when 'error'
        stats[:errors] += 1
      end
    end
    
    def log_final_stats(stats)
      Jekyll.logger.info "BatchProcessor:", "Batch processing complete:"
      Jekyll.logger.info "BatchProcessor:", "  - Processed: #{stats[:processed]}"
      Jekyll.logger.info "BatchProcessor:", "  - Translated: #{stats[:translated]}"
      Jekyll.logger.info "BatchProcessor:", "  - From cache: #{stats[:cached]}"
      Jekyll.logger.info "BatchProcessor:", "  - Skipped: #{stats[:skipped]}"
      Jekyll.logger.info "BatchProcessor:", "  - Errors: #{stats[:errors]}"
    end
  end
end

# Jekyll plugin hook for batch processing
Jekyll::Hooks.register :site, :post_read do |site|
  if ENV['JEKYLL_BATCH_TRANSLATE'] == 'true'
    Jekyll.logger.info "BatchProcessor:", "Batch translation mode enabled"
    batch_processor = Jekyll::BatchProcessor.new(site)
    batch_processor.process_all_posts
  end
end