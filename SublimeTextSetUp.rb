#! /usr/bin/env ruby
require 'tmpdir'
require 'optparse'; options = {:coffee_script => false, :test => false, :cleanup => false}
#consider substituting FileUtils.cp_r w/ FileUtils.install if possible.

option_parser = OptionParser.new("Default Use is no Options.") do |opts|
  opts.program_name = "Sublime Text 2 Editor Rails Set-up install script."
  opts.on('-t', '--test', 
    "Testing only Writes to:\n\t\t\t\t\t #{ENV['HOME']}/.temp dir.") do
    options[:test] = true
    options[:cleanup] = true
    options[:coffee_script] = true
  end
  opts.on('-u', '--cleanup', "Removes temp directory contents, default for JRuby") do
    options[:cleanup] = true
  end
end
option_parser.parse!
  
# COLORIZE OUTPUT
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

## DETERMINE OS windows? mac? linux? install directories
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

def check_exit_code(exit_code= $?.exitstatus, message= "#{caller().first}")
  #raise if exit code ($?) not good (0)
  raise message unless exit_code == 0 
  exit_code
end

## Set paths ##
sublime_packages_path, sublime_user_packages_path = set_sublime_dir
tempdir_path = Dir.mktmpdir
puts Msg.new("Downloading to temp dir: #{tempdir_path}").color(:blue)
Dir.chdir(tempdir_path)

################ For Testing Purposes ###################
# options = {:coffee_script => true, :test => true, :cleanup => true}
if options[:test] == true
  Dir.mkdir("#{ENV['HOME']}/.temp") unless File.exists?("#{ENV['HOME']}/.temp")
  sublime_packages_path = "#{ENV['HOME']}/.temp"
  sublime_user_packages_path = "#{ENV['HOME']}/.temp"
  puts Msg.new("##TESTING##").color(:red)
end
#########################################################

## TEST requirements ##
def test_requirements(sublime_packages_path, sublime_user_packages_path)
  #Test paths set correctly
  a1, a2 = sublime_packages_path, sublime_user_packages_path
  raise "Can't find Sublime dir: #{a1}" unless File.exists?(a1) && File.directory?(a1)
  raise "Can't find Sublime dir: #{a2}" unless File.exists?(a2) && File.directory?(a2)
  #Test if Git is installed or exit
  git_version = %x[git --version]
  abort("Git Required") unless git_version.match(/^git version [1-9]\.[1-9]\.[1-9]/)
  # rvm_installed = ENV['PATH']['rvm'] #!%x[which rvm].empty?
end
test_requirements(sublime_packages_path, sublime_user_packages_path)

## Install Packages ##
def install_SASS(sublime_packages_path)#Install SASS Higlighting
  %x[git clone https://github.com/n00ge/sublime-text-haml-sass.git]
  check_exit_code()
  Dir.chdir("sublime-text-haml-sass") do
    if RUBY_PLATFORM === "java"
      ec = FileUtils.mv('SASS', (sublime_packages_path + "/"), :verbose => true, :force => true )
      check_exit_code(ec)
    else
      FileUtils::Verbose.cp_r('SASS', sublime_packages_path)
    end
    FileUtils.cp_r('Ruby Haml', sublime_packages_path)
  end
  puts Msg.new("Installed SASS and Haml highlighting.").color(:green)
end
install_SASS(sublime_packages_path)

def install_Snippets(sublime_packages_path)#Install Rails Tutorial Snippets
  %x[git clone git@github.com:mhartl/rails_tutorial_snippets.git RailsTutorial]
  check_exit_code()
  FileUtils.rm_r('RailsTutorial/.git') if File.exists?('RailsTutorial/.git')
  FileUtils.cp_r('RailsTutorial', sublime_packages_path)
  puts Msg.new("Installed Rails Tutorial Snippets.").color(:green)
end
install_Snippets(sublime_packages_path)

def install_AltAutoComplete(sublime_packages_path)#Install Alternative Auto-completion
  %x[git clone git://github.com/alexstaubo/sublime_text_alternative_autocompletion.git]
  check_exit_code()
  contents_of_directory = Dir.glob('sublime_text_alternative_autocompletion/*.py*')
  contents_of_directory.each do |file|
    FileUtils.cp(file, sublime_packages_path)
  end
  puts Msg.new("Installed Alternative Auto-completion.").color(:green)
end
install_AltAutoComplete(sublime_packages_path)

def install_RubyTest(sublime_packages_path)#Install RubyTest
  %x[git clone https://github.com/maltize/sublime-text-2-ruby-tests.git RubyTest]
  check_exit_code()
  FileUtils.rm_r('RubyTest/.git') if File.exists?('RubyTest/.git')
  FileUtils.cp_r('RubyTest', sublime_packages_path)
end
install_RubyTest(sublime_packages_path)

def update_theme_file(path) #THEMES
  puts 'Updating file "Theme - Default/widget.sublime-settings" with new settings'
  file_contents = File.read(path +"/Theme - Default/Widget.sublime-settings").gsub(
    "Packages/Theme - Default/Widgets.stTheme",
    "Packages/User/CustomTestConsole.tmTheme") 
  File.open(path + "/Theme - Default/Widget.sublime-settings", "w+") do |file| 
    file.write(file_contents)
  end
end
#Logic Here is weird fix up.
update_theme_file(sublime_packages_path) if File.exists?(sublime_packages_path + \
  "/Theme - Default/Widget.sublime-settings")
puts Msg.new("Installed RubyTest.").color(:green)

#Instal Coffee-Script Build ##Still TESTING this
def install_CoffeeScriptBuild(sublime_packages_path)
  coffee_path = `which coffee`.chomp.split("/")[0...-1].join("/") 
  Dir.mkdir("#{sublime_packages_path}/CoffeeScript")
  File.open("#{sublime_packages_path}/CoffeeScript/CoffeeScript.sublime-build", "w+") do
    puts %Q`{"cmd": ["coffee", "$file"],\n"selector" : "source.coffee",\n"path" : "#{coffee_path}"}`
  end unless File.exists?("#{sublime_packages_path}/CoffeeScript/CoffeeScript.sublime-build")
  puts Msg.new("Installed CoffeeScript Build").color(:green)
end
if options[:coffee_script] && !`which coffee`.empty?
  install_CoffeeScriptBuild(sublime_packages_path)
end

#Ones that install on the user path

def install_AuxFiles(sublime_user_packages_path) #AUX Files
  #Install Auxiliary files rails_tutorial_sublime_text
  %x[git clone git@github.com:mhartl/rails_tutorial_sublime_text.git]
  contents_of_directory = Dir.glob('rails_tutorial_sublime_text/*')
  contents_of_directory.each do |file|
    FileUtils.cp(file , sublime_user_packages_path)
    #Can this copy be changed for install??
  end
  puts Msg.new("Installed Auxiliary files for rails tutorial.").color(:green)
end
install_AuxFiles(sublime_user_packages_path)

def install_ERB(sublime_user_packages_path) #Install Sublime ERB 
  %x[git clone git@github.com:eddorre/SublimeERB.git sublime_erb]
  check_exit_code()
  FileUtils.rm_r('sublime_erb/.git') if File.exists?('sublime_erb/.git')
  FileUtils.cp_r('sublime_erb', sublime_user_packages_path)
  puts Msg.new("Installed Sublime ERB (needs manual action below to complete).").color(:yellow)
  puts Msg.new("open the Preferences>KeyBindings-User file and add: ").color(:yellow)
  puts %Q`{ "keys": ["ctrl+shift+."], "command": "erb" }`
end
install_ERB(sublime_user_packages_path)

#Clean up TestDirectory if JRuby due to non-actual-temp dir location
if RUBY_PLATFORM == "java" or options[:cleanup]
  puts Msg.new("Cleaning up Temp Directory").color(:blue)
  FileUtils.rm_rf(tempdir_path, :verbose => true)
end
