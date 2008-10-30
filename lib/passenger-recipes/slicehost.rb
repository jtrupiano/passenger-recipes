require 'highline/import'

module Capistrano
  module Servers
    module Prompt
      def ui
        @ui ||= HighLine.new
      end

      # Prompt for a password using echo suppression.
      def password_prompt(prompt="Password: ")
        ui.ask(prompt) { |q| q.echo = false }
      end
    end
    
    module Slicehost
      class Ubuntu
        include Capistrano::Servers::Prompt
        
        attr_reader :config
        def initialize(config)
          @config = config
        end
        
        def build
          
        end
        
        def setup
          # It would be cool to provide a feedback loop here to ensure that the values are set properly...
          # :apache_group, :deploy_to, :user, :application, and :target_os (only :ubuntu and :centos are supported)
          #puts "\nBy default, passenger-recipes is configured such that deploy:setup does not execute any remote commands.  All of these tasks should be executed manually on your server using an appropriately-privileged user account.\n\n"
          #puts "To get accurate values for the commands below, you should set the following variables: :apache_group, :deploy_to, :user, :application, and :target_os (only :ubuntu and :centos are supported)\n\n"
          
          prompt_for_privileged_user do |deploy_user, deploy_password|
            apache_grp = config.fetch(:apache_group, "<apache_group>")
          
            # only run adduser if the user account doesn't already exist
            adduser = <<-BASH
              cnt=`cat /etc/shadow | grep "^#{deploy_user}:" | wc -l` && \
              if [ "$cnt" -ne "1" ]; then
                echo "Adding user:group #{deploy_user}:#{apache_grp}" && \
                adduser --ingroup #{apache_grp} #{deploy_user};
              else
                echo "User #{deploy_user} already exists.  Skipping...";
              fi
            BASH
            link_target = "/etc/apache2/sites-enabled/#{config.application}.conf"
          
            #puts "adduser: #{adduser}"
            #puts "link_target: #{link_target}"
            #puts "user: #{@config.user}"
            #puts "password: #{@config.password}"
            #config.run("echo $PATH")
            
            config.run(adduser)
            config.run("mkdir -p #{config.releases_path} #{config.content_path} #{config.log_path}")
            config.run("ln -fs #{config.shared_path}/passenger.conf #{link_target}")
            config.run("chown -R #{deploy_user}:#{apache_grp} #{config.deploy_to} #{config.log_path}")
            config.run("chmod 750 #{config.log_path} #{config.deploy_to}")
            sql = <<-SQL
              CREATE DATABASE #{config.db['database']};
              GRANT ALL PRIVILEGES ON #{config.db['database']}.* TO '#{config.db['username']}'@localhost IDENTIFIED BY '#{config.db['password']}';
            SQL
            config.run("mysql -u #{config.db['username']} -p#{config.db['password']} -e \"#{sql.strip}\"")
          end
        end
        
        private
          def prompt_for_privileged_user(&block)
            ui.say("Application requires root (or other privileged access).")
            
            # collect password, override user/password
            username = ui.ask("Enter a valid username: ")
            pass = password_prompt
            old_username = config.fetch(:user)
            old_password = config.fetch(:password)
            config.set(:user, username)
            config.set(:password, pass)
          begin
            yield(old_username, old_password)
          ensure
            # reset user/password
            config.set(:user, old_username)
            config.set(:password, old_password)
          end
        end
      end
    end
  end
end