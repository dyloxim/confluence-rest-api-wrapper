# frozen_string_literal: true

# defines confluence-instance, space & user specific profile which is
# utilised by ConfluenceTask instances.
class Profile
  attr_reader :confluence_instance, :credentials, :space
  def initialize(opts = {})
    @confluence_instance = opts[:confluence_instance] || opts['confluence_instance']
    @credentials = parse_creds(opts[:credentials] || opts['credentials'])
    @space = opts[:space] || opts['space']
  end

  def parse_creds(creds_hash)
    {
      username: creds_hash[:username] || creds_hash['username'],
      password: creds_hash[:password] || creds_hash['password']
    }
  end

  def to_s
    puts "confluence_instance: #{@confluence_instance}"
    puts "credentials: #{@credentials}"
    puts "space: #{@space}"
  end
end
