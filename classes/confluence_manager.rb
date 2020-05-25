# frozen_string_literal: true

# The interface class essentially, all you should need to interact with to get tasks
# done in confluence.
class ConfluenceManager
  include ProfileLoader
  def initialize(name)
    @profile_name = name
  end

  # TODO: add 'overwrite' parameter
  def new(title, body)
    payload = Draft.new(@profile_name, title, body).payload
    query = Query.new(
      method: :post,
      uri: '/rest/api/content',
      payload: payload,
      headers: { content_type: 'application/json' }
    )
    response = ConfluenceTask.new(query: query, profile: profile).run
    Page.new(response.body, @profile_name)
  end

  # this is actually a great contender for most simple operation.
  # does what it says on the tin.
  # Different argument types this needs to handle:
  # - ID
  # - Title
  # - cql
  # Further optimizations:
  # - shorthand for specific, common cql queries - ie:
  #   - label
  #   - title matching
  # OH! another few considerations:
  # 1. 'limit' argument on number of arguments that will be returned
  # 2. 'expand' options. do you want the labels? Do you want the child pages? Do you want the storage format?
  # (maybe this can all be boiled down into a headers argument?)
  # Default headers can be stored in the config file.
  # should return a page object. (meaning no matter the format of
  # the query arguments provided to this method, the output should
  # have attributes that can be accessed in predictable ways like
  # -> read(title: 'thing').first['id']
  # -> read(id: '0asd34sd8fg').first['title']
  # -> read(labels: ['just_this']).map { |page| page['id'] }
  # etc.
  def get(id: nil, title: nil, expand: nil)
    if id.nil?
      get_from_title(title, expand: expand)
    else
      get_from_id(id, expand: expand)
    end
  end

  def get_from_id(id, expand: nil)
    query = Query.new(
      method: :get,
      uri: "/rest/api/content/#{id}",
      headers: { expand: expand || '' }
    )
    response = ConfluenceTask.new(query: query, profile: profile).run
    response
  end

  def get_from_title(title, expand: nil)
    search("title =\"#{title}\"", expand: expand)
  end

  def search(cql, expand: nil)
    query = Query.new(
      method: :get,
      uri: '/rest/api/content/search',
      headers: { expand: expand || '', cql: "#{cql} and space=#{profile.space}" }
    )
    response = ConfluenceTask.new(query: query, profile: profile).run
    PageSet.new(@profile_name, json: response)
  end

  def update
    # update is again not too complicated right?
    # Oh perhaps not actually, it has to deal with many types of update:
    # - update title, update body, update...? update labels
    # labels are special though, because I want it to be possible to remove individual labels,
    # append, or update completely... right?
    # On second thoughts, if the reading/updating in general is smooth enough
    # then these operations can all be done with ordinary data processing
    # methods and shouldn't require special treatment - ie:
    # rather than
    # -> update(page: page, labels: <remove label A>)
    # you would do;
    # -> labels = read(page: page, labels).delete(<label A>)
    # -> update(page: page, labels: labels)
    # much better I think. More uniformity.
    puts 'updating'
  end

  def delete
    # should be quite straightforward... like I have said for all of these.
    # Have some way of guarding the application of the function though - like
    # make it possible to configure patterns that will be checked before running
    # a delete so they won't be performed on certain content without explicit use
    # of something like a 'force: true' argument for example.
    puts 'deleting'
  end
end
