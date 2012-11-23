xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
  xml.rss :version => "2.0", "xmlns:atom" => "http://www.w3.org/2005/Atom" do
    xml.channel do
      if @title
        xml.title "Millwood Online - #{@title}"
      else
        xml.title "Millwood Online"
      end
      if @description
        xml.description @description
      else
        xml.description "Millwood Online Blog features many articles on Drupal, Ruby-on-Rails, Sinatra and related Web Development topics."
      end
      xml.link "#{request.url.gsub('/rss.xml','')}" 
      xml.tag!("atom:link", :href => "#{request.url}", :rel => "self", :type => "application/rss+xml")
      xml.pubDate Time.parse(@contents.first(:fields => [:created]).created.to_s).rfc822
      @contents.each do |content|
        if content.markdown
          body = Maruku.new(content.body).to_html
        else
          body = content.body
        end
        xml.item do
          xml.guid "#{request.url.chomp request.path_info}/blog/#{content.alias}"
          xml.title content.title
          xml.link "#{request.url.chomp request.path_info}/blog/#{content.alias}"
          xml.pubDate Time.parse(content.created.to_s).rfc822
          xml.description "#{body.split('</p>').first} <a href='#{request.url.chomp request.path_info}/blog/#{content.alias}'>Read more</a>"
        end
      end
    end  
  end
