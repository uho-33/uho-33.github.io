require 'yaml'

module Jekyll
  class ProviderConfig
    attr_reader :site, :config, :providers, :default_provider

    def initialize(site)
      @site = site
      @config = site.config['translation'] || {}
      @providers = @config['providers'] || {}
      @default_provider = @config['default_provider'] || 'gemini'
      
      validate_configuration
      initialize_providers
    end

    # Get configuration for a specific provider
    def get_provider_config(provider_name = nil)
      provider_name ||= @default_provider
      
      provider_config = @providers[provider_name]
      unless provider_config
        raise ArgumentError, "Unknown provider: #{provider_name}. Available: #{@providers.keys.join(', ')}"
      end
      
      # Merge with defaults and add runtime information
      {
        'provider' => provider_name,
        'model' => provider_config['model'],
        'api_key_env' => provider_config['api_key_env'],
        'max_tokens' => provider_config['max_tokens'] || 4096,
        'rate_limit' => provider_config['rate_limit'] || 10,
        'timeout' => provider_config['timeout'] || 30,
        'enabled' => provider_config.fetch('enabled', true)
      }
    end

    # Get list of available providers
    def available_providers
      @providers.select { |name, config| config.fetch('enabled', true) }.keys
    end

    # Get provider by priority (enabled providers first, then by preference order)
    def get_best_available_provider
      # Check default provider first
      if provider_available?(@default_provider)
        return @default_provider
      end
      
      # Check other providers in order
      %w[gemini openai claude].each do |provider|
        if provider_available?(provider) && provider != @default_provider
          Jekyll.logger.warn "Default provider '#{@default_provider}' not available, using '#{provider}'"
          return provider
        end
      end
      
      raise "No translation providers are available"
    end

    # Check if a provider is properly configured and available
    def provider_available?(provider_name)
      return false unless @providers.key?(provider_name)
      
      provider_config = @providers[provider_name]
      return false unless provider_config.fetch('enabled', true)
      
      # Check if API key is available
      api_key_env = provider_config['api_key_env']
      return false unless api_key_env && !ENV[api_key_env].to_s.strip.empty?
      
      true
    end

    # Validate API keys for all enabled providers
    def validate_api_keys
      validation_results = {}
      
      available_providers.each do |provider_name|
        provider_config = @providers[provider_name]
        api_key_env = provider_config['api_key_env']
        api_key = ENV[api_key_env]
        
        validation_results[provider_name] = {
          'configured' => !api_key_env.nil?,
          'key_present' => !api_key.to_s.strip.empty?,
          'key_format_valid' => validate_api_key_format(provider_name, api_key),
          'environment_variable' => api_key_env
        }
      end
      
      validation_results
    end

    # Get provider statistics and usage information
    def get_provider_statistics
      stats = {}
      
      @providers.each do |provider_name, config|
        stats[provider_name] = {
          'enabled' => config.fetch('enabled', true),
          'configured' => provider_available?(provider_name),
          'model' => config['model'],
          'rate_limit' => config['rate_limit'],
          'max_tokens' => config['max_tokens'],
          'is_default' => provider_name == @default_provider
        }
        
        # Add runtime availability check
        if stats[provider_name]['configured']
          begin
            # Attempt to create translator instance to verify configuration
            case provider_name
            when 'gemini'
              translator = site.config['gemini_translator']
              stats[provider_name]['runtime_available'] = !translator.nil?
            else
              stats[provider_name]['runtime_available'] = false
              stats[provider_name]['note'] = 'Provider not yet implemented'
            end
          rescue => e
            stats[provider_name]['runtime_available'] = false
            stats[provider_name]['error'] = e.message
          end
        else
          stats[provider_name]['runtime_available'] = false
        end
      end
      
      stats
    end

    # Switch default provider (for testing or fallback scenarios)
    def switch_default_provider(new_provider)
      unless @providers.key?(new_provider)
        raise ArgumentError, "Unknown provider: #{new_provider}"
      end
      
      unless provider_available?(new_provider)
        raise ArgumentError, "Provider '#{new_provider}' is not available"
      end
      
      old_provider = @default_provider
      @default_provider = new_provider
      
      Jekyll.logger.info "Switched default translation provider: #{old_provider} → #{new_provider}"
      
      new_provider
    end

    # Get translation cost estimate (if pricing information available)
    def estimate_translation_cost(text, provider_name = nil)
      provider_name ||= @default_provider
      provider_config = @providers[provider_name]
      
      return nil unless provider_config && provider_config['cost_per_token']
      
      # Rough token estimation
      token_count = (text.length / 4.0).ceil
      cost_per_token = provider_config['cost_per_token'].to_f
      
      {
        'provider' => provider_name,
        'estimated_tokens' => token_count,
        'cost_per_token' => cost_per_token,
        'estimated_cost' => (token_count * cost_per_token).round(6),
        'currency' => provider_config['currency'] || 'USD'
      }
    end

    private

    def validate_configuration
      unless @config['enabled']
        Jekyll.logger.info "Translation system is disabled"
        return
      end
      
      if @providers.empty?
        raise ArgumentError, "No translation providers configured"
      end
      
      unless @providers.key?(@default_provider)
        raise ArgumentError, "Default provider '#{@default_provider}' not found in providers list"
      end
      
      # Warn if no providers are available
      available_count = available_providers.length
      if available_count == 0
        Jekyll.logger.error "No translation providers are properly configured with API keys"
      elsif available_count == 1
        Jekyll.logger.warn "Only one translation provider is available - consider configuring backup providers"
      end
    end

    def initialize_providers
      return unless @config['enabled']
      
      @providers.each do |name, config|
        Jekyll.logger.debug "Configured provider: #{name} (#{config['model']})"
        
        # Validate required fields
        %w[model api_key_env].each do |required_field|
          unless config[required_field]
            Jekyll.logger.error "Provider '#{name}' missing required field: #{required_field}"
          end
        end
      end
    end

    def validate_api_key_format(provider_name, api_key)
      return false if api_key.to_s.strip.empty?
      
      case provider_name
      when 'gemini'
        # Gemini API keys are typically 39 characters starting with 'AI'
        api_key.match?(/^AIza[0-9A-Za-z_-]{35}$/)
      when 'openai'
        # OpenAI API keys start with 'sk-'
        api_key.match?(/^sk-[0-9A-Za-z]{48}$/)
      when 'claude'
        # Anthropic API keys start with 'sk-ant-'
        api_key.match?(/^sk-ant-[0-9A-Za-z_-]+$/)
      else
        # For unknown providers, just check it's not empty and reasonably long
        api_key.length >= 20
      end
    end
  end
  
  # Jekyll integration
  Jekyll::Hooks.register :site, :after_init do |site|
    if site.config.dig('translation', 'enabled')
      begin
        provider_config = ProviderConfig.new(site)
        site.config['provider_config'] = provider_config
        
        # Log provider status
        stats = provider_config.get_provider_statistics
        Jekyll.logger.info "Translation providers initialized:"
        stats.each do |name, info|
          status = info['runtime_available'] ? '✓' : '✗'
          default_marker = info['is_default'] ? ' (default)' : ''
          Jekyll.logger.info "  #{status} #{name}#{default_marker}: #{info['model']}"
        end
        
      rescue => e
        Jekyll.logger.error "Failed to initialize provider configuration: #{e.message}"
      end
    end
  end
  
  # Add a Jekyll command to check provider status
  module Commands
    class ProviderStatus < Jekyll::Command
      def self.init_with_program(prog)
        prog.command(:providers) do |c|
          c.syntax 'providers'
          c.description 'Show translation provider status'
          
          c.action do |args, options|
            site = Jekyll::Site.new(Jekyll.configuration(options))
            
            if site.config.dig('translation', 'enabled')
              provider_config = ProviderConfig.new(site)
              
              puts "\n=== Translation Provider Status ==="
              
              validation = provider_config.validate_api_keys
              stats = provider_config.get_provider_statistics
              
              validation.each do |provider, info|
                puts "\n#{provider.upcase}:"
                puts "  Model: #{stats[provider]['model']}"
                puts "  Configured: #{info['configured'] ? '✓' : '✗'}"
                puts "  API Key (#{info['environment_variable']}): #{info['key_present'] ? '✓' : '✗'}"
                puts "  Key Format: #{info['key_format_valid'] ? '✓' : '✗'}"
                puts "  Runtime Available: #{stats[provider]['runtime_available'] ? '✓' : '✗'}"
                puts "  Default: #{stats[provider]['is_default'] ? '✓' : '✗'}"
                
                if stats[provider]['error']
                  puts "  Error: #{stats[provider]['error']}"
                end
              end
              
              puts "\nAvailable providers: #{provider_config.available_providers.join(', ')}"
              puts "Default provider: #{provider_config.default_provider}"
              
            else
              puts "Translation system is disabled"
            end
          end
        end
      end
    end
  end
end