require 'test/unit'
require 'jekyll'
require 'fileutils'

class BuildTest < Test::Unit::TestCase
  def setup
    @site_source = File.expand_path('..', __dir__)
    @site_dest = File.join(@site_source, '_site')
    
    # Clean previous builds
    FileUtils.rm_rf(@site_dest) if Dir.exist?(@site_dest)
    
    # Build the site
    Jekyll.logger.log_level = :error  # Suppress build output during tests
    @config = Jekyll.configuration({
      'source' => @site_source,
      'destination' => @site_dest,
      'quiet' => true
    })
    @site = Jekyll::Site.new(@config)
  end

  def test_bilingual_site_generation
    # This test MUST FAIL until bilingual functionality is implemented
    @site.process
    
    # Test Chinese (default) site generation
    assert Dir.exist?(@site_dest), "Site destination should exist after build"
    assert File.exist?(File.join(@site_dest, 'index.html')), "Chinese index.html should be generated"
    
    # Test English site generation - WILL FAIL until Polyglot is working
    english_index = File.join(@site_dest, 'en', 'index.html')
    assert File.exist?(english_index), "English index.html should be generated in /en/ subdirectory"
    
    # Test post translation - WILL FAIL until translation plugins are implemented
    chinese_posts = Dir.glob(File.join(@site_dest, 'posts', '*.html'))
    english_posts = Dir.glob(File.join(@site_dest, 'en', 'posts', '*.html'))
    
    refute_empty chinese_posts, "Chinese posts should be generated"
    refute_empty english_posts, "English posts should be generated"
    assert_equal chinese_posts.length, english_posts.length, "Should have equal number of posts in both languages"
  end

  def test_polyglot_plugin_loaded
    # Test if Jekyll-Polyglot plugin is loaded - WILL FAIL until properly configured
    assert @site.plugins.any? { |plugin| plugin.class.name.include?('Polyglot') }, 
           "Jekyll-Polyglot plugin should be loaded"
  end

  def test_language_configuration
    # Test language configuration
    assert_equal ['zh-CN', 'en'], @config['languages'], "Languages should be configured as zh-CN and en"
    assert_equal 'zh-CN', @config['default_lang'], "Default language should be zh-CN"
  end

  def test_translation_provider_configuration
    # Test LLM provider configuration - WILL FAIL until translation system is implemented
    translation_config = @config['translation']
    assert_not_nil translation_config, "Translation configuration should exist"
    assert_equal 'gemini', translation_config['default_provider'], "Default provider should be gemini"
    assert translation_config['providers'].key?('gemini'), "Gemini provider should be configured"
    assert translation_config['providers'].key?('openai'), "OpenAI provider should be configured"
    assert translation_config['providers'].key?('claude'), "Claude provider should be configured"
  end

  def teardown
    # Clean up after tests
    FileUtils.rm_rf(@site_dest) if Dir.exist?(@site_dest)
  end
end