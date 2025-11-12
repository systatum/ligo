namespace :ligo do
  task :set_vars do
    set :daemon_service_filename, "ligo-#{fetch(:deploy_env)}.service"
    set :health_check_name, "health-check-#{fetch(:deploy_env)}"
    set :binary_filename, "ligo-#{fetch(:deploy_env)}"
  end

  desc "Upload binaries to the server"
  task :upload_binaries do
    on roles(:app) do
      binary = fetch(:binary_filename)
      within release_path do
        execute :mkdir, "-p backend/bin"

        upload! File.expand_path("../../../../backend/mybin/#{binary}", __dir__), "#{release_path}/backend/bin"
        upload! File.expand_path("../../../../backend/mybin/manage", __dir__), "#{release_path}/backend/bin"

        execute :chmod, "+x backend/bin/#{binary}"
        execute :chmod, "+x backend/bin/manage"
      end
    end
  end

  desc "Symlink scripts to the server"
  task :symlink_scripts do
    on roles(:app) do
      execute :mkdir, "-p /home/systatum/server-logs"

      daemon_service = fetch(:daemon_service_filename)
      health_check = fetch(:health_check_name)
      stage = fetch(:stage)

      source_daemon = "#{release_path}/deployer/scripts/#{stage}/#{daemon_service}"
      source_rb = "#{release_path}/deployer/scripts/#{stage}/#{health_check}.rb"
      source_service = "#{release_path}/deployer/scripts/#{stage}/#{health_check}.service"
      source_timer = "#{release_path}/deployer/scripts/#{stage}/#{health_check}.timer"

      daemon_path = "/etc/systemd/system/#{daemon_service}"
      rb_path = "/home/systatum/server-logs/#{health_check}.rb"
      service_path = "/etc/systemd/system/#{health_check}.service"
      timer_path = "/etc/systemd/system/#{health_check}.timer"

      execute :sudo, :ln, "-sf", source_daemon, daemon_path
      execute :sudo, :ln, "-sf", source_rb, rb_path
      execute :sudo, :ln, "-sf", source_service, service_path
      execute :sudo, :ln, "-sf", source_timer, timer_path
    end
  end

  desc "Migrate database"
  task :migrate do
    on roles(:db) do
      within release_path.join("backend") do
        execute :bash, "-c", %Q{'echo "#{ENV["LIGO_DB_ENV"]}" > #{release_path}/backend/.env'}

        marten = "#{release_path}/backend/bin/manage"
        execute :"#{marten}", "genmigrations"
        execute :"#{marten}", "migrate"
        execute :"#{marten}", "migrate_system_fields"
      end
    end
  end

  desc "Start the server by executing the scripts"
  task :start do
    on roles(:app) do
      daemon_service = fetch(:daemon_service_filename)
      health_check = fetch(:health_check_name)

      execute :sudo, "systemctl daemon-reload"
      execute :sudo, "systemctl enable #{daemon_service}"
      execute :sudo, "systemctl restart #{daemon_service}"
      execute :sudo, "systemctl enable #{health_check}.timer"
      execute :sudo, "systemctl restart #{health_check}.timer"
    end
  end
end

before "ligo:upload_binaries", "ligo:set_vars"

after "deploy:updated", "ligo:upload_binaries"
after "deploy:published", "ligo:symlink_scripts"
after "ligo:symlink_scripts", "ligo:migrate"
after "ligo:migrate", "ligo:start"
