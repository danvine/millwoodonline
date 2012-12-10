before '/admin/*' do
  enforce_admin
end

get '/admin/content/?' do
  @contents = Content.all(:order => [ :created.desc ])
  @title = 'Content'
  erb File.read './views/content.erb'
end

get '/admin/content/edit/:id/?' do
  id = Sanitize.clean(params[:id])
  @contents = Content.first(:order => [ :created.desc ], :id => id)
  @title = "Edit '#{@contents.title}'"
 
  erb File.read './views/addcontent.erb'
end

post '/admin/content/edit/:id/?' do
  content_attributes = params[:content]
  id = Sanitize.clean(params[:id])
  content = Content.get(id)
  content.content_tags.all.destroy
  content_attributes['tags'].split(',').each do |tag|
    tag_data = Tag.first_or_create(:tag => tag.lstrip.rstrip)
    content.tags << tag_data
  end
  content.title = content_attributes['title']
  content.type = 'blog'
  content.body = content_attributes['body']
  content.alias = content_attributes['alias']
  if content_attributes['file']
    content.file = upload(content_attributes['file'][:filename], content_attributes['file'][:tempfile])
  end
  content.markdown = content_attributes['markdown']
  content.published = content_attributes['published']? true : false
  content.created = Time.now if content_attributes['update_created']
  content.save
  redirect "/admin/content/edit/#{id}"
end

get '/admin/content/add/?' do
  @title = 'Add Content'
  erb File.read './views/addcontent.erb'
end

post '/admin/content/add/?' do
  content_attributes = params[:content]
  content = Content.create
  content_attributes['tags'].split(',').each do |tag|
    tag_data = Tag.first_or_create(:tag => tag.lstrip.rstrip)
    content.tags << tag_data
  end
  content.title = content_attributes['title']
  content.type = 'blog'
  content.body = content_attributes['body']
  content.alias = content_attributes['alias']
  content.markdown = content_attributes['markdown']
  content.published = content_attributes['published']? true : false
  content.created = Time.now if content_attributes['update_created']
  content.save

  if content_attributes['published']
    redirect "/blog/#{content.alias}"
  else
    redirect "/admin/content"
  end  
end