require 'yaml'
require 'fileutils'
require 'digest'

module Jekyll
  class TranslationCacheManager
    attr_reader :site, :cache_dir, :metadata_dir

    def initialize(site)
      @site = site
      @cache_dir = File.join(site.source, '_data', 'translations', 'posts')
      @metadata_dir = File.join(site.source, '_data', 'translations', 'metadata')
      
      # Ensure directories exist
      FileUtils.mkdir_p(@cache_dir)
      FileUtils.mkdir_p(@metadata_dir)
      
      @stats = load_statistics
    end

    # Check if translation exists in cache
    def translation_exists?(content_hash, provider)
      cache_file = cache_file_path(content_hash, provider)
      File.exist?(cache_file)
    end

    # Get cached translation
    def get_cached_translation(content_hash, provider)
      cache_file = cache_file_path(content_hash, provider)
      
      return nil unless File.exist?(cache_file)
      
      begin
        cached_data = YAML.load_file(cache_file)
        
        # Update access statistics
        update_access_time(cache_file, cached_data)
        
        cached_data
      rescue => e
        Jekyll.logger.warn "Failed to load cached translation: #{e.message}"
        nil
      end
    end

    # Store translation in cache
    def store_translation(content_hash, original_content, translated_content, provider, metadata = {})
      cache_file = cache_file_path(content_hash, provider)
      
      cache_data = {
        'source_hash' => content_hash,
        'source_content' => original_content,
        'translated_content' => translated_content,
        'provider' => provider,
        'created_at' => Time.now.utc.iso8601,
        'last_used' => Time.now.utc.iso8601,
        'quality_score' => metadata[:quality_score] || 0.9,
        'token_count' => metadata[:token_count] || estimate_token_count(original_content + translated_content),
        'processing_time' => metadata[:processing_time] || 0.0
      }
      
      begin
        File.write(cache_file, cache_data.to_yaml)
        
        # Update statistics
        update_statistics(provider, :cache_write, cache_data['token_count'])
        
        Jekyll.logger.info "Cached translation: #{content_hash[0..7]}... (#{provider})"
        
        true
      rescue => e
        Jekyll.logger.error "Failed to cache translation: #{e.message}"
        false
      end
    end

    # Clean up old cache entries
    def cleanup_cache(max_age_days = 90)
      cutoff_time = Time.now - (max_age_days * 24 * 60 * 60)
      cleaned_count = 0
      
      Dir.glob(File.join(@cache_dir, '*.yml')).each do |cache_file|
        begin
          cached_data = YAML.load_file(cache_file)
          last_used = Time.parse(cached_data['last_used'])
          
          if last_used < cutoff_time
            File.delete(cache_file)
            cleaned_count += 1
            Jekyll.logger.info "Cleaned up old cache file: #{File.basename(cache_file)}"
          end
        rescue => e
          Jekyll.logger.warn "Failed to process cache file #{cache_file}: #{e.message}"
        end
      end
      
      Jekyll.logger.info "Cache cleanup completed: removed #{cleaned_count} old entries"
      cleaned_count
    end

    # Get cache statistics
    def get_statistics
      stats = @stats.dup
      
      # Add current cache size
      stats['cache_files'] = Dir.glob(File.join(@cache_dir, '*.yml')).length
      
      # Calculate total cache size
      total_size = Dir.glob(File.join(@cache_dir, '*.yml')).sum { |f| File.size(f) rescue 0 }
      stats['cache_size_mb'] = (total_size / 1024.0 / 1024.0).round(2)
      
      stats
    end

    # Generate cache report
    def generate_cache_report
      report = {
        'generated_at' => Time.now.utc.iso8601,
        'statistics' => get_statistics,
        'providers' => {},
        'recent_activity' => []
      }
      
      # Analyze cache by provider
      Dir.glob(File.join(@cache_dir, '*.yml')).each do |cache_file|
        begin
          cached_data = YAML.load_file(cache_file)
          provider = cached_data['provider']
          
          report['providers'][provider] ||= {
            'count' => 0,
            'total_tokens' => 0,
            'avg_quality' => 0.0,
            'oldest' => nil,
            'newest' => nil
          }
          
          provider_stats = report['providers'][provider]
          provider_stats['count'] += 1
          provider_stats['total_tokens'] += cached_data['token_count'] || 0
          
          created_at = Time.parse(cached_data['created_at'])
          provider_stats['oldest'] = created_at if provider_stats['oldest'].nil? || created_at < provider_stats['oldest']
          provider_stats['newest'] = created_at if provider_stats['newest'].nil? || created_at > provider_stats['newest']
          
          # Add to recent activity if within last 7 days
          if created_at > Time.now - (7 * 24 * 60 * 60)
            report['recent_activity'] << {
              'date' => created_at.strftime('%Y-%m-%d'),
              'provider' => provider,
              'content_preview' => cached_data['source_content'][0..50] + '...',
              'tokens' => cached_data['token_count']
            }
          end
        rescue => e
          Jekyll.logger.warn "Failed to analyze cache file #{cache_file}: #{e.message}"
        end
      end
      
      # Calculate averages and format dates
      report['providers'].each do |provider, stats|
        if stats['count'] > 0
          stats['avg_tokens'] = (stats['total_tokens'] / stats['count']).round(1)
        end
        stats['oldest'] = stats['oldest'].strftime('%Y-%m-%d') if stats['oldest']
        stats['newest'] = stats['newest'].strftime('%Y-%m-%d') if stats['newest']
      end
      
      # Sort recent activity by date
      report['recent_activity'].sort_by! { |activity| activity['date'] }.reverse!
      
      report
    end

    # Invalidate cache for specific content
    def invalidate_translation(content_hash, provider = nil)
      if provider
        cache_file = cache_file_path(content_hash, provider)
        if File.exist?(cache_file)
          File.delete(cache_file)
          Jekyll.logger.info "Invalidated cached translation: #{content_hash[0..7]}... (#{provider})"
          return true
        end
      else
        # Invalidate all providers for this content hash
        pattern = File.join(@cache_dir, "#{content_hash}_*.yml")
        invalidated = 0
        
        Dir.glob(pattern).each do |cache_file|
          File.delete(cache_file)
          invalidated += 1
        end
        
        if invalidated > 0
          Jekyll.logger.info "Invalidated #{invalidated} cached translations for: #{content_hash[0..7]}..."
          return true
        end
      end
      
      false
    end

    private

    def cache_file_path(content_hash, provider)
      File.join(@cache_dir, "#{content_hash}_#{provider}.yml")
    end

    def update_access_time(cache_file, cached_data)
      cached_data['last_used'] = Time.now.utc.iso8601
      File.write(cache_file, cached_data.to_yaml)
      
      # Update statistics
      update_statistics(cached_data['provider'], :cache_hit, cached_data['token_count'] || 0)
    end

    def load_statistics
      stats_file = File.join(@metadata_dir, 'cache_stats.yml')
      
      if File.exist?(stats_file)
        YAML.load_file(stats_file)
      else
        initialize_statistics
      end
    rescue => e
      Jekyll.logger.warn "Failed to load cache statistics: #{e.message}"
      initialize_statistics
    end

    def initialize_statistics
      {
        'cache_hits' => 0,
        'cache_writes' => 0,
        'total_tokens_cached' => 0,
        'total_tokens_hit' => 0,
        'providers' => {},
        'last_updated' => Time.now.utc.iso8601
      }
    end

    def update_statistics(provider, action, token_count)
      @stats['last_updated'] = Time.now.utc.iso8601
      @stats['providers'][provider] ||= { 'hits' => 0, 'writes' => 0, 'tokens' => 0 }
      
      case action
      when :cache_hit
        @stats['cache_hits'] += 1
        @stats['total_tokens_hit'] += token_count
        @stats['providers'][provider]['hits'] += 1
      when :cache_write
        @stats['cache_writes'] += 1
        @stats['total_tokens_cached'] += token_count
        @stats['providers'][provider]['writes'] += 1
        @stats['providers'][provider]['tokens'] += token_count
      end
      
      save_statistics
    end

    def save_statistics
      stats_file = File.join(@metadata_dir, 'cache_stats.yml')
      File.write(stats_file, @stats.to_yaml)
    rescue => e
      Jekyll.logger.error "Failed to save cache statistics: #{e.message}"
    end

    def estimate_token_count(text)
      # Rough estimation: ~4 characters per token for mixed Chinese/English
      (text.length / 4.0).ceil
    end
  end
  
  # Jekyll plugin integration
  Jekyll::Hooks.register :site, :after_init do |site|
    # Initialize cache manager as site plugin
    site.config['translation_cache_manager'] = TranslationCacheManager.new(site)
  end
  
  # Clean up old cache entries on build
  Jekyll::Hooks.register :site, :post_write do |site|
    cache_manager = site.config['translation_cache_manager']
    if cache_manager && ENV['JEKYLL_CACHE_CLEANUP'] == 'true'
      cache_manager.cleanup_cache
    end
  end
end