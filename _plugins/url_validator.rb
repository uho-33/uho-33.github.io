require 'jekyll'

# Ensure all URLs use HTTPS in production and fix common URL issues
Jekyll::Hooks.register :site, :post_write do |site|
  next unless site.config['env'] == 'production' || ENV['JEKYLL_ENV'] == 'production'
  
  site_url = site.config['url']
  next unless site_url&.start_with?('https://')
  
  dest = site.dest
  
  # Fix localhost URLs in generated files
  Dir.glob(File.join(dest, '**', '*.html')).each do |file_path|
    begin
      content = File.read(file_path, mode: 'r:UTF-8')
      
      # Replace http://localhost:4000 with proper site URL
      if content.include?('http://localhost:4000')
        new_content = content.gsub('http://localhost:4000', site_url)
        File.write(file_path, new_content, mode: 'w:UTF-8')
        Jekyll.logger.info 'URLValidator', "Fixed localhost URLs in #{file_path.sub(dest, '')}"
      end
      
      # Replace any remaining http:// with https:// for the site domain
      domain = site_url.gsub('https://', '')
      if content.include?("http://#{domain}")
        new_content = content.gsub("http://#{domain}", site_url)
        File.write(file_path, new_content, mode: 'w:UTF-8')
        Jekyll.logger.info 'URLValidator', "Fixed HTTP URLs in #{file_path.sub(dest, '')}"
      end
      
    rescue => e
      Jekyll.logger.warn 'URLValidator', "Failed to process #{file_path}: #{e.message}"
    end
  end
end
