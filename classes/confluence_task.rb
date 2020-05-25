# frozen_string_literal: true

# Classes:
# The main class - used for all interactions with the REST API.
# Used for running individual queries on a single connection
class ConfluenceTask
  attr_accessor :result, :query
  def initialize(profile: dev_profile, query: default_query)
    @profile = profile
    @query = query
  end

  def to_s
    puts "profile: #{@profile}"
    puts "query: #{@query}"
  end

  def run
    conn = Faraday::Connection.new(@profile.confluence_instance)
    conn.basic_auth(@profile.credentials[:username], @profile.credentials[:password])
    @query.runner.call(conn)
  ensure
    conn.close
  end
end
