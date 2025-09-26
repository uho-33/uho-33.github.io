module Jekyll
  class BuildHooks
    
    # Hook: After site is read, check for translation needs
    Jekyll::Hooks.register :site, :post_read do |site|
      translation_config = site.config['translation']
      next unless translation_config&.dig('enabled')
      
      Jekyll.logger.info "BuildHooks:", "Checking for translation requirements"
      
      # Initialize translation processor
      processor = TranslationProcessor.new(site)
      
      # Process posts that need translation
      posts_needing_translation = find_posts_needing_translation(site)
      
      if posts_needing_translation.any?
        Jekyll.logger.info "BuildHooks:", "Found #{posts_needing_translation.size} posts needing translation"
        
        # Check if auto-translation is enabled
        if translation_config.dig('auto_translate') == true
          process_translations_during_build(site, posts_needing_translation, processor)
        else
          log_translation_recommendations(posts_needing_translation)
        end
      else
        Jekyll.logger.info "BuildHooks:", "No posts require translation"
      end
    end
    
    # Hook: Before site generation, ensure English posts are included
    Jekyll::Hooks.register :site, :pre_render do |site|
      translation_config = site.config['translation']
      next unless translation_config&.dig('enabled')
      
      Jekyll.logger.info "BuildHooks:", "Pre-render: Checking English post availability"
      
      # Scan for English posts and add them to site.posts if needed
      english_posts_dir = File.join(site.source, '_posts', 'en')
      
      if Dir.exist?(english_posts_dir)
        english_post_files = Dir.glob(File.join(english_posts_dir, '*.md'))
        
        english_post_files.each do |post_path|
          # Check if this English post is already in site.posts
          relative_path = Pathname.new(post_path).relative_path_from(Pathname.new(site.source)).to_s
          
          existing_post = site.posts.docs.find { |p| p.relative_path == relative_path }
          
          unless existing_post
            Jekyll.logger.info "BuildHooks:", "Adding English post: #{relative_path}"
            
            # Create post object and add to collection
            post = Jekyll::Document.new(post_path, {
              site: site,
              collection: site.posts
            })
            
            post.read
            site.posts.docs << post
          end
        end
      end
    end
    
    # Hook: After site generation, validate translation completeness
    Jekyll::Hooks.register :site, :post_render do |site|
      translation_config = site.config['translation']
      next unless translation_config&.dig('enabled')
      
      Jekyll.logger.info "BuildHooks:", "Post-render: Validating translation completeness"
      
      validation_results = validate_translation_completeness(site)
      
      if validation_results[:issues].any?
        Jekyll.logger.warn "BuildHooks:", "Translation validation issues found:"
        validation_results[:issues].each do |issue|
          Jekyll.logger.warn "BuildHooks:", "  - #{issue}"
        end
      else
        Jekyll.logger.info "BuildHooks:", "All translations validated successfully"
      end
    end
    
    # Hook: After site write, generate translation reports
    Jekyll::Hooks.register :site, :post_write do |site|
      translation_config = site.config['translation']
      next unless translation_config&.dig('enabled')
      
      if translation_config.dig('generate_reports') == true
        Jekyll.logger.info "BuildHooks:", "Generating translation reports"
        generate_translation_report(site)
      end
    end
    
    private
    
    def self.find_posts_needing_translation(site)
      site.posts.docs.select do |post|
        begin
          # Skip posts already in English
          next false if post.data['lang'] == 'en'
          
          # Skip if post content is nil or empty
          next false unless post.content && !post.content.empty?
          
          # Check if Chinese content is present
          chinese_segments = ContentFilter.detect_chinese_segments(post.content)
          has_chinese = chinese_segments.any? { |segment| segment[:type] == 'chinese' }
          
          # Check if English version already exists
          english_post_path = generate_english_post_path(site, post.path)
          english_exists = File.exist?(english_post_path)
          
          has_chinese && !english_exists
        rescue => e
          Jekyll.logger.error "ContentFilter:", "Error processing #{post.path}: #{e.message}"
          false
        end
      end
    end
    
    def self.process_translations_during_build(site, posts, processor)
      Jekyll.logger.info "BuildHooks:", "Auto-translating #{posts.size} posts during build"
      
      cache_manager = TranslationCacheManager.new(site.config)
      
      posts.each_with_index do |post, index|
        begin
          Jekyll.logger.info "BuildHooks:", "Translating post #{index + 1}/#{posts.size}: #{post.data['title']}"
          
          # Generate content hash for caching
          content_hash = Digest::SHA256.hexdigest(post.content)[0...16]
          
          # Check cache first
          cached_translation = cache_manager.get_cached_translation(
            post.path,
            content_hash,
            'zh-CN',
            'en'
          )
          
          if cached_translation
            Jekyll.logger.info "BuildHooks:", "Using cached translation"
            translation_content = cached_translation
            provider = 'cached'
          else
            # Perform translation
            result = processor.translate_content(post.content, 'zh-CN', 'en')
            
            if result[:success]
              translation_content = result[:content]
              provider = result[:provider]
              
              # Cache the result
              cache_manager.store_translation(
                post.path,
                content_hash,
                'zh-CN',
                'en',
                translation_content,
                provider
              )
            else
              Jekyll.logger.error "BuildHooks:", "Failed to translate #{post.path}: #{result[:error]}"
              next
            end
          end
          
          # Create English post file
          create_english_post_during_build(site, post, translation_content, provider)
          
          # Rate limiting
          sleep(site.config.dig('translation', 'rate_limit', 'delay_between_posts') || 0.5)
          
        rescue StandardError => e
          Jekyll.logger.error "BuildHooks:", "Error processing #{post.path}: #{e.message}"
        end
      end
    end
    
    def self.create_english_post_during_build(site, original_post, translated_content, provider)
      english_post_path = generate_english_post_path(site, original_post.path)
      
      # Create directory if needed
      FileUtils.mkdir_p(File.dirname(english_post_path))
      
      # Generate English frontmatter
      frontmatter = original_post.data.dup
      frontmatter['lang'] = 'en'
      frontmatter['original_language'] = original_post.data['lang'] || 'zh-CN'
      frontmatter['translation_provider'] = provider
      frontmatter['translated_at'] = Time.now.iso8601
      
      # Translate title if needed
      begin
        if frontmatter['title'] && !frontmatter['title'].empty? && 
           ContentFilter.detect_chinese_segments(frontmatter['title']).any?
          processor = TranslationProcessor.new(site)
          title_result = processor.translate_content(frontmatter['title'], 'zh-CN', 'en')
          frontmatter['title'] = title_result[:content] if title_result[:success]
        end
      rescue => e
        Jekyll.logger.error "ContentFilter:", "Error translating title: #{e.message}"
      end
      
      # Create full content
      yaml_frontmatter = "---\n#{frontmatter.to_yaml.gsub(/^---\n/, '')}---"
      full_content = "#{yaml_frontmatter}\n#{translated_content}"
      
      # Write file
      File.write(english_post_path, full_content)
      
      Jekyll.logger.info "BuildHooks:", "Created English post: #{english_post_path}"
    end
    
    def self.generate_english_post_path(site, original_path)
      relative_path = Pathname.new(original_path).relative_path_from(Pathname.new(site.source))
      base_name = File.basename(relative_path)
      posts_dir = File.dirname(File.join(site.source, relative_path))
      
      File.join(posts_dir, 'en', base_name)
    end
    
    def self.log_translation_recommendations(posts)
      Jekyll.logger.info "BuildHooks:", "Posts recommended for translation:"
      posts.each do |post|
        Jekyll.logger.info "BuildHooks:", "  - #{post.data['title']} (#{post.path})"
      end
      Jekyll.logger.info "BuildHooks:", "To auto-translate, set 'translation.auto_translate: true' in _config.yml"
    end
    
    def self.validate_translation_completeness(site)
      issues = []
      
      # Check for Chinese posts without English versions
      chinese_posts = site.posts.docs.select do |post|
        begin
          post.data['lang'] != 'en' && 
          post.content && !post.content.empty? &&
          ContentFilter.detect_chinese_segments(post.content).any? { |s| s[:type] == 'chinese' }
        rescue => e
          Jekyll.logger.error "ContentFilter:", "Error validating #{post.path}: #{e.message}"
          false
        end
      end
      
      chinese_posts.each do |post|
        english_path = generate_english_post_path(site, post.path)
        unless File.exist?(english_path)
          issues << "Chinese post without English translation: #{post.data['title']}"
        end
      end
      
      # Check for orphaned English posts
      english_posts = site.posts.docs.select { |post| post.data['lang'] == 'en' }
      
      english_posts.each do |post|
        if post.data['original_language']
          # Try to find corresponding original post
          original_found = site.posts.docs.any? do |original|
            original.data['lang'] != 'en' && 
            File.basename(original.path) == File.basename(post.path)
          end
          
          unless original_found
            issues << "English post without corresponding original: #{post.data['title']}"
          end
        end
      end
      
      { issues: issues, chinese_posts: chinese_posts.size, english_posts: english_posts.size }
    end
    
    def self.generate_translation_report(site)
      report_path = File.join(site.dest, 'translation-report.json')
      
      cache_manager = TranslationCacheManager.new(site.config)
      cache_stats = cache_manager.get_statistics
      
      validation_results = validate_translation_completeness(site)
      
      report = {
        generated_at: Time.now.iso8601,
        posts: {
          total: site.posts.docs.size,
          chinese: validation_results[:chinese_posts],
          english: validation_results[:english_posts]
        },
        cache: cache_stats,
        issues: validation_results[:issues],
        translation_config: site.config['translation'] || {}
      }
      
      File.write(report_path, JSON.pretty_generate(report))
      Jekyll.logger.info "BuildHooks:", "Translation report generated: #{report_path}"
    end
  end
end