get '/node/:nid/?' do
  nid = Sanitize.clean(params[:nid])
  contents = Content.first(:type => 'blog', :id => nid, :fields => [:alias])
  if contents.nil?
    halt 404
  end
  redirect '/blog/' + contents.alias, 301
end

get '/taxonomy/term/25' do
  redirect '/tag/drupal', 301
end