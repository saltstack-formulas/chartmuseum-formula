task :prepare do
  sh "docker-compose up -d"
end


task :test => [:destroy, :prepare] do
  sh "bundle exec kitchen test"
end

task verify: :prepare do
  sh "bundle exec kitchen verify"
end

task :destroy do
  puts "Destroying Kitchen environment..."
  begin
    sh "bundle exec kitchen destroy"
  rescue Exception => e
    puts "Failed to destroy kitchen environment #{e}"
  end

  puts "Destroying docker resources..."
  begin
    sh "docker rm -f chartmuseum"
  rescue
  end

  sh "docker-compose down -v"
end