# config valid only for current version of Capistrano
lock '3.4.0'

set :application, 'kwoon'
set :repo_url, 'git@github.com:cdidyk/kwoon.git'

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, '/srv/kwoon'
set :puma_pid, '/srv/kwoon/shared/tmp/puma/pid'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml')
set :linked_files, fetch(:linked_files, []).push('.env', '.ruby-version', 'config/puma.rb')


# Default value for linked_dirs is []
# set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/puma', 'tmp/cache')

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

# only keep the last 2 sets of cached assets
set :keep_assets, 2
set :assets_roles, [:web, :app]

namespace :deploy do

  # after :restart, :clear_cache do
  #   on roles(:web), in: :groups, limit: 3, wait: 10 do
  #     # Here we can do anything such as:
  #     # within release_path do
  #     #   execute :rake, 'cache:clear'
  #     # end
  #   end
  # end

  after :finished, :start_puma do
    on roles(:web) do
      restart = (
        test "[ -f #{fetch(:puma_pid)} ]" and
        test :kill, "-0 $( cat #{fetch(:puma_pid)} )"
      )

      if restart
        execute :service, "puma restart"
      else
        execute :service, "puma start"
      end
    end
  end

end
