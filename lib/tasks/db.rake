# thanks to github user hopsoft: https://gist.github.com/hopsoft/56ba6f55fe48ad7f8b90
namespace :db do

  desc "Dumps the database to db/APP_NAME.dump"
  task :dump => :environment do
    cmd = nil
    with_config do |app, host, db, user|
      cmd = "pg_dump --host #{host} --username #{user} --verbose --clean --no-owner --no-acl --format=c #{db} > #{Rails.root}/db/#{app}.dump"
    end
    puts cmd
    exec cmd
  end

  desc "Restores the database dump at db/APP_NAME.dump."
  task :restore => :environment do
    cmd = nil
    with_config do |app, host, db, user|
      cmd = "pg_restore --verbose --host #{host} --username #{user} --clean --no-owner --no-acl --dbname #{db} #{Rails.root}/db/#{app}.dump"
    end
    Rake::Task["db:drop"].invoke
    Rake::Task["db:create"].invoke
    puts cmd
    exec cmd
  end

  private

  CONFIG_ATTRS = [:host, :database, :username]

  def with_config
    config =
      ActiveRecord::Base.connection_config
        .select {|k,v| CONFIG_ATTRS.include? k }
    config[:host] ||= "localhost"
    config[:username] ||= ENV['USER']

    p "DB connection info for dump/restore:\n host: #{config[:host]}\nusername: #{config[:username]}\ndatabase: #{config[:database]}"

    yield Rails.application.class.parent_name.underscore,
      config[:host],
      config[:database],
      config[:username]
  end

end