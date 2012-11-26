xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
  xml.urlset "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9" do
    
    ["", "/about", "/work", "/php-drupal-web-developer-cardiff-abergavenny-wales-uk", "/ruby-on-rails-sinatra-web-developer-cardiff-abergavenny-wales-uk", "/blog", "/contact", "/tag", "/archive"].each do |path|
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

    archive = repository(:default).adapter.select("select to_char(created, 'YYYY MM') as created_year_month, count(id) as num from contents where published = TRUE and type = 'blog' group by created_year_month order by created_year_month desc")
    archive.each do |month|
      xml.url do
        xml.loc "#{request.url.chomp request.path_info}/archive/#{month[:created_year_month].gsub(' ', '')}"
        xml.changefreq "daily"
        xml.priority "0.3"
      end
    end
  end