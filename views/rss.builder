xml.instruct! :xml, :version => "1.0"
  xml.rss :version => "2.0" do
    xml.channel do
      xml.title "Millwood Online"
      xml.link request.url
      @contents.each do |content|
        xml.item do
          xml.title content.title
          xml.link "#{request.url.chomp request.path_info}/blog/#{content.alias}"
          xml.guid "#{request.url.chomp request.path_info}/blog/#{content.alias}"
          xml.pubDate Time.parse(content.created.to_s).rfc822
          xml.description content.body
        end
      end
    
    end
  end
