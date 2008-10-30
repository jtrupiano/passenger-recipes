require 'passenger-recipes/slicehost'

Capistrano::Configuration.instance(:must_exist).load do
  abort "passenger-recipes is not compatible with Capistrano 1.x." unless respond_to?(:namespace)

  # Load in the common stuff
  require 'capistrano-extensions/deploy'
  puts "Loading Passenger Recipes"

  # Override these at your own discretion!
  _cset(:apache_conf) {"#{latest_release}/config/#{rails_env}/apache.conf"}
  _cset(:apache_group, "www-data")
  #_cset(:apache_restart_cmd, "/usr/sbin/apache2ctl")
  _cset(:default_shell, "/bin/bash")

  def ensure_not_root
    raise "Do not deploy as root" if user == "root"
  end
  
  def read_password
    system "stty -echo"
    readline("")
    system "stty echo"
  end

  # Finally, our passenger-specific recipes.
  namespace :deploy do
    desc <<-DESC
      [passenger]: Displays onscreen the set of privileged tasks you should manually 
      execute on your server.  We advise you to manually execute these as root,
      and then proceed with deployment using a non-privileged user.  Execute this task
      for specific instructions.
    DESC
    task :setup, :except => { :no_release => true } do
      
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
        load_schema
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
      [passenger]: Outputs a message to the user telling them to manually log in and restart apache.
      Could potentially allow you to actually execute a command by checking to see if the user has exec
      rights on the file (via a dependency), but I'm just not sure if we want to allow the deployment
      user to restart apache. 
    DESC
    # Hard restarts apache-- the command for this is configurable via the :apache_restart_cmd property.
    task :restart_apache, :roles => :app do
      puts "********** LOG INTO THE SERVER AND RESTART APACHE NOW SO THAT YOUR NEW PASSENGER SITE WILL BE SERVED UP ********"
      #run "#{apache_restart_cmd} restart"
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
      symlinks to the shared directory for the log and tmp directories, and \
      will lastly touch all assets in public/images, public/stylesheets, and \
      public/javascripts so that the times are consistent (so that asset \
      timestamping works).  This touch process is only carried out if the \
      :normalize_asset_timestamps variable is set to true, which is the default.
    DESC
    task :finalize_update, :except => { :no_release => true } do
      run "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)

      # mkdir -p is making sure that the directories are there for some SCM's that don't
      # save empty folders
      run <<-CMD
        rm -rf #{latest_release}/log &&
        mkdir -p #{latest_release}/public &&
        mkdir -p #{latest_release}/tmp &&
        ln -s #{log_path} #{latest_release}/log
      CMD

      create_shared_file_column_dirs # defined in capistrano-extensions
      
      if fetch(:normalize_asset_timestamps, true)
        stamp = Time.now.utc.strftime("%Y%m%d%H%M.%S")
        asset_paths = %w(images stylesheets javascripts).map { |p| "#{latest_release}/public/#{p}" }.join(" ")
        run "find #{asset_paths} -exec touch -t #{stamp} {} ';'; true", :env => { "TZ" => "UTC" }
      end
    end

  end
  
  namespace :servers do
    
    desc <<-DESC
      [passenger]: Takes the default Ubuntu 8.04 Server Image from Slicehost and prepares a baseline install
      ready for a single machine, using a MySQL 5.2 database, Apache 2.2.8, Passenger 2.0.3 (actually the most recent
      stable release).  Additional setup should be applied manually. 
    DESC
    task :build do
      puts "Put our Ubuntu_Slicehost wiki page content hya"
    end
    
    desc <<-DESC
      [passenger]: On a properly built Ubuntu slice, this will perform the necessary setup procedures for a single
      machine install.  It sets up your shared content directories, your log directory (/var/log/<:application>),
      chown's the directories to a lesser-privileged user (<:user>:<:apache_group>).  It will also create your
      database.
    DESC
    task :setup do
      # It would be cool to provide a feedback loop here to ensure that the values are set properly...
      # :apache_group, :deploy_to, :user, :application, and :target_os (only :ubuntu and :centos are supported)
      #puts "\nBy default, passenger-recipes is configured such that deploy:setup does not execute any remote commands.  All of these tasks should be executed manually on your server using an appropriately-privileged user account.\n\n"
      #puts "To get accurate values for the commands below, you should set the following variables: :apache_group, :deploy_to, :user, :application, and :target_os (only :ubuntu and :centos are supported)\n\n"
      # apache_grp = fetch(:apache_group, "<apache_group>")
      # 
      # adduser     = "adduser --ingroup #{apache_grp} #{user}"
      # link_target = "/etc/apache2/sites-enabled/#{application}.conf"
      # 
      # run(adduser)
      # run("mkdir -p #{releases_path} #{content_path} #{log_path}")
      # run("ln -fs #{shared_path}/passenger.conf #{link_target}")
      # run("chown -R #{user}:#{apache_grp} #{deploy_to} #{log_path}")
      # run("chmod 750 #{log_path} #{deploy_to}")
      # sql = <<-SQL
      #   CREATE DATABASE #{db['database']};
      #   GRANT ALL PRIVILEGES ON #{db['database']}.* TO '#{db['username']}'@localhost IDENTIFIED BY '#{db['password']}';
      # SQL
      # run("mysql -e \"#{sql}\"")
      
      puts "cap server:setup invoked"
      server = Capistrano::Servers::Slicehost::Ubuntu.new(self)
      server.setup
    end
  end
      
  # namespace :centos do        
  #     task :setup do
  #       # adduser     = "useradd -G #{apache_grp} #{user}"
  #       # link_target = "/etc/httpd/conf.d/#{application}.conf"
  #       # server::slicehost::general::setup
  #     end
  #   end  
  
  desc <<-DESC
    [internal] [passenger]: Loads the schema.rb file using rake db:schema:load.
    This task is invoked during deploy:cold.  migrate is used in deploy:default.
  DESC
  task :load_schema, :roles => :db, :only => { :primary => true } do
    rake = fetch(:rake, "rake")

    run "cd #{release_path}; #{rake} RAILS_ENV=#{rails_env} db:schema:load"
  end
end
