helpers do
  def blockload
    @block = erb :block, :layout => false
  end
  
  def enforce_admin
    if !current_user.admin?
      halt 403
    end
  end
end
