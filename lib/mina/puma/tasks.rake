require 'mina/bundler'
require 'mina/rails'

namespace :puma do
  set :web_server, :puma

  set_default :puma_role,      -> { user }
  set_default :puma_env,       -> { fetch(:rails_env, 'production') }
  set_default :puma_config,    -> { "#{deploy_to}/#{shared_path}/config/puma.rb" }
  set_default :puma_socket,    -> { "#{deploy_to}/#{shared_path}/tmp/sockets/puma.sock" }
  set_default :puma_state,     -> { "#{deploy_to}/#{shared_path}/tmp/sockets/puma.state" }
  set_default :puma_pid,       -> { "#{deploy_to}/#{shared_path}/tmp/pids/puma.pid" }
  set_default :puma_cmd,       -> { "#{bundle_prefix} puma" }
  set_default :pumactl_cmd,    -> { "#{bundle_prefix} pumactl" }
  set_default :pumactl_socket, -> { "#{deploy_to}/#{shared_path}/tmp/sockets/pumactl.sock" }

  desc 'Start puma'
  task :start => :environment do
    in_directory "#{deploy_to}/#{current_path}" do
      queue! %(#{puma_cmd} #{start_options})
    end
  end

  desc 'Stop puma'
  task stop: :environment do
    in_directory "#{deploy_to}/#{current_path}" do
      queue! %(#{pumactl_cmd} -S #{puma_state} stop)
    end
  end

  desc 'Restart puma'
  task restart: :environment do
    in_directory "#{deploy_to}/#{current_path}" do
      if check_exists?(pumactl_socket)
        queue! %(#{pumactl_cmd} -S #{puma_state} restart)
      else
        queue! %(#{puma_cmd} #{start_options})
      end
    end
  end

  private

    def start_options
      if check_exists?(puma_config)
        "-q -d -e #{puma_env} -C #{puma_config}"
      else
        "-q -d -e #{puma_env} -b 'unix://#{puma_socket}' -S #{puma_state} --control 'unix://#{pumactl_socket}'"
      end
    end

    def check_exists?(file)
      boolean = capture("if [ -a '#{file}' ]; then echo 'yes'; else echo 'no'; fi").chomp
      boolean == 'yes' ? true : false
    end
end
