require 'aruba/api'
require 'aruba/cucumber'
require 'fileutils'
require 'vim-flavor'

class FakeUserEnvironment
  include Vim::Flavor::ShellUtility

  def initialize()
    env = self
    Vim::Flavor::Flavor.instance_eval do
      @github_repo_uri = lambda {|user, repo|
        "file://#{env.expand('$tmp')}/repos/#{user}/#{repo}"
      }
    end
  end

  def create_file path, content
    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, 'w') do |f|
      f.write(content)
    end
  end

  def delete_path path
    FileUtils.remove_entry_secure(path)
  end

  def expand(virtual_path)
    virtual_path.gsub(/\$([a-z_]+)/) {
      variable_table[$1]
    }
  end

  def make_flavor_path(vimfiles_path, repo_name)
    "#{vimfiles_path.to_flavors_path}/#{repo_name.zap}"
  end

  def make_repo_path(basename)
    "#{expand("$tmp")}/repos/#{basename}"
  end

  def make_repo_uri(basename)
    "file://#{make_repo_path(basename)}"
  end

  def variable_table
    @variable_table ||= Hash.new
  end
end

Before do
  variable_table['tmp'] = File.absolute_path(current_dir)

  steps %Q{
    Given a directory named "home"
  }
  variable_table['home'] = File.absolute_path(File.join([current_dir, 'home']))
end

Aruba.configure do |config|
  config.before_cmd do |cmd|
    set_env 'HOME', variable_table['home']
    set_env 'VIM_FLAVOR_GITHUB_URI_PREFIX', expand('file://$tmp/repos/')
    set_env 'VIM_FLAVOR_GITHUB_URI_SUFFIX', ''
  end
end

World do
  FakeUserEnvironment.new
end

ENV['THOR_DEBUG'] = '1'  # To raise an exception as is.
