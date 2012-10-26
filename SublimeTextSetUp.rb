#! /usr/bin/env ruby
require 'tmpdir'

class Msg < String
  def colorize(color_code)
    #from StackOverflow [http://stackoverflow.com/questions/1489183/colorized-ruby-output]
    STDOUT.tty? ? "\e[1m\e[#{color_code}m#{self}\e[0m" : self
  end
  def color(*args)
    colours = {:red => 31, :green => 32, :yellow => 33, :blue => 34}
    self.send :colorize, colours[args[0]]
  end
end

#figure out windows? mac? linux? install directories
def set_sublime_dir(system = RUBY_PLATFORM)
  Dir.respond_to?(:home) ? home = Dir.home : home = ENV['HOME']
  case system
  when /mingw/, /Windows/
    sublime_packages_path = home + "/AppData/Roaming/Sublime Text 2/Packages"
    sublime_user_packages_path = home + "/AppData/Roaming/Sublime Text 2/Packages/User"
  when /darwin/, /Mac/
    sublime_packages_path = home + "/Library/Application Support/Sublime Text 2/Packages"
    sublime_user_packages_path = home + "/Library/Application Support/Sublime Text 2/Packages/User"
  when /linux/i
    sublime_packages_path = home + "/.config/sublime-text-2/Packages"
    sublime_user_packages_path = home + "/.config/sublime-text-2/Packages/User"
  when /java/
    require 'java'
    java_os_result = java.lang.System.get_property('os.name')
    sublime_packages_path, sublime_user_packages_path = set_sublime_dir(java_os_result)
    puts Msg.new("JRuby support experimental").color(:red) 
    #abort("JRuby not Supported") 
    #In *Winodws* there is a **Bug in JRuby** Dir.cp_r copying unicode-named folders:
    #RuntimeError: unknown file type: SASS/Commands/Insert ColorGC??.tmCommand
    #copy at C:/RailsInstaller/jruby-1.7.0.RC1/lib/ruby/1.9/fileutils.rb:1374
    #Real file name: Insert ColorGCÌ§Âª.tmCommand
    #Also Dir.mktmpdr seems to be created in the local directory.
  end
  [sublime_packages_path, sublime_user_packages_path]
end

def check_exit_code(message= "#{caller().first}")
  #raise if exit code ($?) not good (0)
  raise message unless $?.to_i === 0 
  $?.to_i
end

## Set paths ##
sublime_packages_path, sublime_user_packages_path = set_sublime_dir
tempdir_path = Dir.mktmpdir
puts Msg.new("Downloading to temp dir: #{tempdir_path}").color(:blue)
Dir.chdir(tempdir_path)
#Test paths set correctly
  raise unless File.exists?(sublime_packages_path) 
  raise unless File.exists?(sublime_user_packages_path) 

#Test if Git is installed or exit
git_version = %x[git --version]
  abort("Git Required") unless git_version.match(/^git version [1-9]\.[1-9]\.[1-9]/)
# rvm_installed = ENV['PATH']['rvm'] #!%x[which rvm].empty?

################ For Testing Purposes ###################
# sublime_packages_path = "#{ENV['HOME']}/.temp"
# sublime_user_packages_path = "#{ENV['HOME']}/.temp"
# puts Msg.new("#TESTING#").color(:red)
#########################################################

#Install SASS Higlighting
%x[git clone https://github.com/n00ge/sublime-text-haml-sass.git]
check_exit_code()
Dir.chdir("sublime-text-haml-sass") do
  if RUBY_PLATFORM === "java"
    FileUtils.mv('SASS', (sublime_packages_path + "/"), :verbose => true, :force => true )
  else
    FileUtils.cp_r('SASS', sublime_packages_path)
  end
  check_exit_code()
  FileUtils.cp_r('Ruby Haml', sublime_packages_path)
  check_exit_code()
end
#Dir.chdir(tempdir_path)
puts Msg.new("Installed SASS and Haml highlighting.").color(:green)

#Install Rails Tutorial Snippets
%x[git clone git@github.com:mhartl/rails_tutorial_snippets.git RailsTutorial]
check_exit_code()
FileUtils.rm_r('RailsTutorial/.git') if File.exists?('RailsTutorial/.git')
check_exit_code()
FileUtils.cp_r('RailsTutorial', sublime_packages_path)
check_exit_code()
puts Msg.new("Installed Rails Tutorial Snippets.").color(:green)

#Install Alternative Auto-completion
%x[git clone git://github.com/alexstaubo/sublime_text_alternative_autocompletion.git]
check_exit_code()
contents_of_directory = Dir.glob('sublime_text_alternative_autocompletion/*.py*')
contents_of_directory.each do |file|
  FileUtils.cp(file, sublime_packages_path)
  check_exit_code()
end
puts Msg.new("Installed Alternative Auto-completion.").color(:green)

#Install RubyTest
%x[git clone https://github.com/maltize/sublime-text-2-ruby-tests.git RubyTest]
check_exit_code()
FileUtils.rm_r('RubyTest/.git') if File.exists?('RubyTest/.git')
check_exit_code()
FileUtils.cp_r('RubyTest', sublime_packages_path)
check_exit_code()

def update_theme_file(path)
  puts 'Updating file "Theme - Default/widget.sublime-settings" with new settings'
  file_contents = File.read(path +"/Theme - Default/Widget.sublime-settings").gsub(
    "Packages/Theme - Default/Widgets.stTheme",
    "Packages/User/CustomTestConsole.tmTheme") 
  File.open(path + "/Theme - Default/Widget.sublime-settings", "w+") do |file| 
    file.write(file_contents)
  end
  check_exit_code()
end
update_theme_file(sublime_packages_path) if File.exists?(sublime_packages_path + \
  "/Theme - Default/Widget.sublime-settings")
puts Msg.new("Installed RubyTest.").color(:green)

#Ones that install on the user path
#Install Auxiliary files rails_tutorial_sublime_text
%x[git clone git@github.com:mhartl/rails_tutorial_sublime_text.git]
contents_of_directory = Dir.glob('rails_tutorial_sublime_text/*')
contents_of_directory.each do |file|
  FileUtils.cp(file , sublime_user_packages_path)
  check_exit_code()
end
puts Msg.new("Installed Auxiliary files for rails tutorial.").color(:green)

#Install Sublime ERB 
%x[git clone git@github.com:eddorre/SublimeERB.git sublime_erb]
check_exit_code()
FileUtils.rm_r('sublime_erb/.git') if File.exists?('sublime_erb/.git')
check_exit_code()
FileUtils.cp_r('sublime_erb', sublime_user_packages_path)
check_exit_code()
puts Msg.new("Installed Sublime ERB (needs manual action below to complete).").color(:yellow)
puts Msg.new("open the Preferences>KeyBindings-User file and add: ").color(:yellow)
puts %Q`{ "keys": ["ctrl+shift+."], "command": "erb" }`

if RUBY_PLATFORM == "java"
  puts Msg.new("Cleaning up Temp Directory").color(:blue)
  FileUtils.rm_rf(tempdir_path, :verbose => true) if RUBY_PLATFORM == "java"
end

=begin
if Linux (or Mac??) && RVM
path on the Build System may need to be adjusted.
  on the Packages/Ruby/Ruby.sublime-build
  file "ruby" should be replaced w/ "/home/$USER/.rvm/bin/rvm-auto-ruby"
=end