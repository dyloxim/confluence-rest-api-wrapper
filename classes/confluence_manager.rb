# frozen_string_literal: true

# entry point for all REST interactions
class ConfluenceManager
  include ProfileLoader
  def initialize(name)
    @profile_name = name
  end

  # TODO: add optional 'overwrite' parameter
  def new(title:, body: nil)
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

  # TODO: implement
  def update
    puts 'updating'
  end

  # TODO: implement
  def delete
    puts 'deleting'
  end
end
