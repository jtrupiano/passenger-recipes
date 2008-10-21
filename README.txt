= passenger-recipes

* http://github.com/jtrupiano/passenger-recipes/tree/master

== DESCRIPTION:
This gem provides a set of recipes for deploying with Passenger.  It's much
more restrictive than Capistrano in the sense that it 'locks down' some 
aspects of what Capistrano actually allows.  See the FEATURES section
below for more specific details.

== INCOMPLETE ==
* Missing a detailed sample config file
* This README is still quite sparse-- add in summaries for each new task
* Describe changes to default deploy recipes
* Discuss dependencies a bit more
* Implement OS-specific default values (Ubuntu and CentOS at a minimum)

== FEATURES/PROBLEMS:

* Enforces non-root deployment.  The deploy:setup task does not actually 
  execute anything, but rather outputs a set of instructions for you 
  to manually execute.  The reason for this is that certain aspects of 
  setting up a server require root access.  Incremental deployment, by 
  contrast, does not require this level of privilege.  As such, I
  recommend that you take care of setting up your server manually.
  
  Note: to "lift" this restriction, you can simply override the 
  :ensure_not_root function.  e.g.
  
  def ensure_not_root; end
  
  However, this is not recommended, considering Apache needs to own all 
  of your files.

* Sets up a symlink in the shared directory (passenger.conf) that is
  updated on each successive deploy.  This allows you to change your
  apache config through a deployment.  You'll need to log in manually 
  as a privileged user to restart apache.

* NEW PROPERTIES --> DEFAULTS
  # Where is the apache config snippet 
  :apache_conf --> {"#{latest_release}/config/#{rails_env}/apache.conf"}

  # Which group does apache run as
  :apache_group --> www-data
  
== SYNOPSIS:

  FIX (code sample of usage)

== REQUIREMENTS:

* capistrano-extensions 0.1.4

== INSTALL:

* rake gem
* sudo gem install pkg/passenger-recipes-0.1.2.gem --local

== LICENSE:

(The MIT License)

Copyright (c) 2008 FIX

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
