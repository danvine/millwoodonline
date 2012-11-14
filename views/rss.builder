xml.instruct! :xml, :version => "1.0"
  xml.feed :xmlns =>"http://www.w3.org/2005/Atom" do
      xml.id request.url
      xml.title "Millwood Online"
      xml.subtitle "Millwood Online Blog features many articles on Drupal, Ruby-on-Rails, Sinatra and related Web Development topics."
      xml.link :type => 'text/html', :rel => "alternate", :href => "#{request.url.chomp request.path_info}/blog"
      xml.link :type => 'application/atom+xml', :rel => "self", :href => request.url 
      xml.updated Time.parse(@contents.first(:fields => [:created]).created.to_s).iso8601(0)
      @contents.each do |content|
        xml.entry do
          xml.id "#{request.url.chomp request.path_info}/blog/#{content.alias}"
          xml.title content.title
          xml.link :href => "#{request.url.chomp request.path_info}/blog/#{content.alias}"
          xml.updated Time.parse(content.created.to_s).iso8601(0)
          xml.content content.body.split('</p>').first, :type => "html"
          xml.author do
            xml.name "Tim Millwood"
            xml.uri "#{request.url.chomp request.path_info}"
          end
        end
      end  
  end
