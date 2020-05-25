# frozen_string_literal: true

begin
  require 'yaml'
  require 'erb'

  def config
    YAML.safe_load(File.read(File.join(__dir__, 'config.yml')))
  end

  require 'rubygems'
  require 'bundler/setup'
  Bundler.require(:default)

  def path(file_name, ext: nil)
    if ext.nil?
      File.join(Dir.pwd, file_name)
    else
      File.join(Dir.pwd, file_name, ext)
    end
  end

  Dir[path('util', ext: '*.rb')].sort.each { |file| require file }
  Dir[path('modules', ext: '*.rb')].sort.each { |file| require file }
  Dir[path('classes', ext: '*.rb')].sort.each { |file| require file }

  def erb(template_name, binding)
    ERB.new(File.read(path("templates/#{template_name}.erb"))).result(binding)
  end

  def profile_details(name)
    YAML.safe_load(File.read(File.join(__dir__, 'profiles.yml')))[name]
  end
end
