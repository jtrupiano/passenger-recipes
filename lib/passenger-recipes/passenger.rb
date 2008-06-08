Capistrano::Configuration.instance(:must_exist).load do
  abort "This version of sls_recipes is not compatible with Capistrano 1.x." unless respond_to?(:namespace)

  # Load in the common stuff
  require 'capistrano-extensions/deploy'
  puts "Loading Passenger Recipes"

  # Override these at your own discretion!
  _cset(:apache_conf) {"#{latest_release}/config/#{rails_env}/apache.conf"}

  # variables introduced in 0.1.3
  _cset(:apache_group, "www-data")
  _cset(:apache_conf_dir, "/etc/apache2/sites-enabled")
  _cset(:apache_restart_cmd, "/usr/sbin/apache2ctl")

  # variables introduced in 0.1.4
  _cset(:normalize_asset_timestamps, true)

  # dependencies
  depend(:remote, :gem, "geminstaller", "0.4.1")            # ensure Chad Wooley's gem is installed
  depend(:remote, :command, "geminstaller")                 # ensure the geminstaller executable can be found
  depend(:remote, :executable, "\`which geminstaller\`")    # ensure that we can execute it
  depend(:remote, :executable, lambda {apache_restart_cmd}) # ensure that our user can restart apache

  def ensure_not_root
    raise "Do not deploy as root" if user == "root"
  end

  # Finally, our passenger-specific recipes.
  namespace :deploy do
    desc <<-DESC
      [passenger]: Displays onscreen the set of privileged tasks you should manually 
      execute on your server.  We advise you to manually execute these as root,
      and then proceed with deployment using a non-privileged user.  Execute this task
      for specific instructions.
    DESC
    task :setup do
      puts "We at SLS will no longer be using the deploy:setup task.  All of these tasks should be executed manually.\n"
      apache_grp = fetch(apache_group, "<apache_group>")
      puts <<-TEXT
        1) $> adduser --group #{apache_grp} deploy
        2) $> mkdir -p #{release_path} #{content_path} #{log_path}
        3) $> chown -R #{user}:#{apache_grp} #{deploy_to} #{log_path}
        4) $> chmod 750 #{log_path}
        5) $> ln -fs #{apache_conf} #{shared_path}/passenger.conf
        6) $> chmod -R 755 #{deploy_to}
        7) mysql> CREATE DATABASE #{db['database']};
                  GRANT ALL PRIVILEGES ON #{db['database']}.* TO '#{db['username']}'@localhost IDENTIFIED BY '#{db['password']}';

        Lastly, don't forget to set the capistrano variable :apache_group
      TEXT
    end
    
    desc <<-DESC
      [passenger]: Executes a cold deployment.  Assumes that the steps detailed in deploy:setup have
      been manually executed, and that no previous releases have been deployed (or that they have all
      been removed).  Note that this task runs deploy:check before allowing you to deploy.
    DESC
    task :cold do
      ensure_not_root
      check # let's not deploy if are dependencies aren't met
      transaction do
        update
        gem_update
        migrate
        link_apache_config
        restart_apache
      end
    end
    
    desc <<-DESC
      [passenger]: Executes an iterative deployment.  Assumes the app is already up and running.
      Invoke this task directly if there are no changes to your Apache config file.  Otherwise,
      invoke deploy:with_restart.
    DESC
    task :default do
      ensure_not_root
      check # let's not deploy if are dependencies aren't met
      transaction do
        update
        gem_update
        migrate
        link_apache_config
        restart_app
      end
    end
    
    desc <<-DESC
      [passenger]: Just a regular deploy that also hard restarts apache.  This task should be invoked
      when the apache config file is changed.  Otherwise deploy is sufficient.
    DESC
    task :with_restart do
      default
      restart_apache
    end

    desc <<-DESC
      [internal] [passenger]: Drops a symlink into apache's sites-enabled directory.  This task
      should be followed by a restart of apache.
    DESC
    task :link_apache_config, :roles => :app do
      server_file = "#{shared_path}/passenger.conf"
      on_rollback { run "ln -fs #{previous_release}/config/#{rails_env}/apache.conf #{server_file}" }
      run "ln -fs #{apache_conf} #{server_file}"
    end
    
    desc <<-DESC
      [passenger]: Hard restarts apache-- the command for this is configurable via the :apache_restart_cmd
      property.
    DESC
    task :restart_apache, :roles => :app do
      run "#{apache_restart_cmd} restart"
    end
    
    desc <<-DESC
      [passenger]: Soft restarts Passenger by touching /tmp/restart.txt, forcing Apache to reload 
      the Rails context on the next request.
    DESC
    task :restart_app, :roles => :app do
      run "touch #{latest_release}/tmp/restart.txt"
    end
    
    # Overwritten
    desc <<-DESC
      [internal] [passenger]: Touches up the released code. This is called by update_code \
      after the basic deploy finishes. It assumes a Rails project was deployed, \
      so if you are deploying something else, you may want to override this \
      task with your own environment's requirements.

      This task will make the release group-writable (if the :group_writable \
      variable is set to true, which is the default). It will then set up \
      symlinks to the shared directory for the log, system, and tmp/pids \
      directories, and will lastly touch all assets in public/images, \
      public/stylesheets, and public/javascripts so that the times are \
      consistent (so that asset timestamping works).  This touch process \
      is only carried out if the :normalize_asset_timestamps variable is \
      set to true, which is the default.
    DESC
    task :finalize_update, :except => { :no_release => true } do
      run "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)

      # mkdir -p is making sure that the directories are there for some SCM's that don't
      # save empty folders
      run <<-CMD
        rm -rf #{latest_release}/log #{latest_release}/public/system &&
        mkdir -p #{latest_release}/public &&
        mkdir -p #{latest_release}/tmp &&
        ln -s #{log_path} #{latest_release}/log &&
        ln -s #{shared_path}/system #{latest_release}/public/system
      CMD

      create_shared_file_column_dirs # defined in capistrano-extensions
      
      if fetch(:normalize_asset_timestamps, true)
        stamp = Time.now.utc.strftime("%Y%m%d%H%M.%S")
        asset_paths = %w(images stylesheets javascripts).map { |p| "#{latest_release}/public/#{p}" }.join(" ")
        run "find #{asset_paths} -exec touch -t #{stamp} {} ';'; true", :env => { "TZ" => "UTC" }
      end
    end

  end
end
