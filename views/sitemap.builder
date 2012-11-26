xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
  xml.urlset "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9" do
    
    ["", "/about", "/work", "/php-drupal-web-developer-cardiff-abergavenny-wales-uk", "/ruby-on-rails-sinatra-web-developer-cardiff-abergavenny-wales-uk", "/blog", "/contact", "/tag"].each do |path|
      xml.url do
        xml.loc "#{request.url.chomp request.path_info}#{path}"
        xml.lastmod Time.now.strftime("%Y-%m-%d")
        xml.changefreq "daily"
        xml.priority "1.0"
      end
    end
    @contents.each do |content|
      xml.url do
        xml.loc "#{request.url.chomp request.path_info}/blog/#{content.alias}"
        xml.lastmod content.created.strftime("%Y-%m-%d")
        xml.changefreq "daily"
        xml.priority "0.5"
      end
    end

    @tags.each do |tag|
      xml.url do
        xml.loc "#{request.url.chomp request.path_info}/tag/#{tag.tag}"
        xml.changefreq "daily"
        xml.priority "0.3"
      end
    end  
  end