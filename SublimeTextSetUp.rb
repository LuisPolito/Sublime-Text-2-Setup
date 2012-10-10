#! /usr/bin/env ruby
require 'tmpdir'
begin
  require 'rainbow'
rescue LoadError
  puts "To get color out put install the gem 'rainbow' with 'gem install rainbow'"
end

class Msg < String
  def color(*args)
    "".respond_to?(:color) ? super : self
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
    puts "JRuby support experimental" #abort("JRuby not Supported") 
    #There is a **Bug in JRuby** Dir.cp_r copying unicode-named folders in Windows:
    #RuntimeError: unknown file type: SASS/Commands/Insert ColorGC??.tmCommand
    #copy at C:/RailsInstaller/jruby-1.7.0.RC1/lib/ruby/1.9/fileutils.rb:1374
    #Real file name: Insert ColorGCÌ§Âª.tmCommand
  end
  [sublime_packages_path, sublime_user_packages_path]
end

def check_exit_code(message= "#{caller().first}")
  #raise if exit code ($?) not good (0)
  raise message unless $?.to_i === 0 
  $?.to_i
end

# def jruby?
#   RUBY_PLATFORM === "java"
# end

## Set paths ##
sublime_packages_path, sublime_user_packages_path = set_sublime_dir
tempdir_path = Dir.mktmpdir
puts "Using temp dir: #{tempdir_path}"
Dir.chdir(tempdir_path)
#Test paths set correctly
  raise unless File.exists?(sublime_packages_path) 
  raise unless File.exists?(sublime_user_packages_path) 

#Test if Git is installed or exit
gitver = %x[git --version]
  abort("Git Required") unless gitver.match(/^git version [1-9]\.[1-9]\.[1-9]/)

################ For Testing Purposes ###################
# sublime_packages_path = "C:/Sites/Packages"
# sublime_user_packages_path = "C:/Sites/User"
#########################################################

#Install SASS Higlighting
%x[git clone https://github.com/n00ge/sublime-text-haml-sass.git]
Dir.chdir("sublime-text-haml-sass") do
  if RUBY_ENGINE === "jruby"
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
puts Msg.new("Installed Sublime ERB (needs manual action to complete).").color(:yellow)
puts 'open keybindings file add   { "keys": ["ctrl+shift+."], "command": "erb" }'


