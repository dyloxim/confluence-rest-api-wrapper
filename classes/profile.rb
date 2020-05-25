# frozen_string_literal: true

# Needed operations:
# - create
# - read
# - update
# - delete
#
# create is floating
# read is floating
# update and delete belong to a page object
#
# if a 'create' request finds that a page already exists,
# an 'override' could be used to re-route the arguments to a combination
# of 'read' followed by 'update'
#
# furthermore, all of these operations need to apply to more than
# just page bodies. there are also labels to be dealt with.
#
# So these methods actually ... belong to something, I could make them
# member methods of the profile class.
#
# This also makes sense because it means I don't have to pass the profile
# to each method. Excellent idea infact!
#
# Used to manage user credentials essentially
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
