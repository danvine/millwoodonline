DataMapper.setup(:default, ENV['HEROKU_POSTGRESQL_SILVER_URL'])
      class Content
        include DataMapper::Resource

        property :id,       Serial
        property :type,     String
        property :title,    String, :length => 256
        property :body,     Text
        property :created,  DateTime
        property :alias,    String, :length => 256
        property :tags,     String, :length => 256
        property :published, Boolean, :default  => false
      end
DataMapper.auto_upgrade!
