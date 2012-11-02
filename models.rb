DataMapper.setup(:default, ENV['HEROKU_POSTGRESQL_SILVER_URL'])
      class Content
        include DataMapper::Resource

        property :id,       Serial, :unique_index =>true
        property :type,     String, :index => true
        property :title,    String, :length => 256
        property :body,     Text
        property :created,  DateTime
        property :alias,    String, :length => 256, :index => true
        property :tags,     String, :length => 256, :index => true
        property :published, Boolean, :default  => false, :index => true
      end
DataMapper.auto_upgrade!
