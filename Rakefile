require 'bundler'
Bundler::GemHelper.install_tasks

desc "Build the C extensions"
task :build_extensions do
  Dir.chdir(File.expand_path('../ext/openssl', __FILE__)) do
    sh 'make distclean' if File.exists? 'Makefile'
    sh 'ruby extconf.rb && make'
  end
end
