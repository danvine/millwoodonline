worker_processes 3
timeout 30
preload_app true

before_fork do |server, worker| 
  DataObjects::Pooling.pools.each do |pool| 
     pool.dispose 
  end 
end 