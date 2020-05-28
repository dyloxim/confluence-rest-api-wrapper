# frozen_string_literal: true

# entry point for all REST interactions
class ConfluenceManager
  include ProfileLoader
  def initialize(name)
    @profile_name = name
  end

  # PAGE METHODS:

  # TODO: add optional 'overwrite' parameter
  def new_page(title:, body: nil, overwrite: false)
    payload = Draft.new(self, with: { title: title, body: body }).payload
    query = Query.new(method: :post, uri: '/rest/api/content', payload: payload)
    response = ConfluenceTask.new(query: query, profile: profile).run
    return Page.new(self, response.body) unless
    response.status != 200 && overwrite == true

    update_page(title: title, with: { body: body })
  end

  def get_page(id: nil, title: nil, expand: nil)
    if id.nil?
      search_pages("title =\"#{title}\"", expand: expand).first
    else
      query = Query.new(
        method: :get, uri: "/rest/api/content/#{id}",
        headers: { expand: [expand].flatten }
      )
      response = ConfluenceTask.new(query: query, profile: profile).run
      Page.new(self, response.body)
    end
  end

  def search_pages(cql, expand: nil)
    query = Query.new(
      method: :get,
      uri: '/rest/api/content/search',
      headers: { expand: [expand].flatten,
                 cql: "#{cql} and space=#{profile.space} and type=page" }
    )
    response = ConfluenceTask.new(query: query, profile: profile).run
    PageSet.new(self, json: response)
  end

  def delete_page(id: nil, title: nil)
    id ||= get_page(title: title).id
    query = Query.new(
      method: :delete,
      uri: "/rest/api/content/#{id}"
    )
    ConfluenceTask.new(query: query, profile: profile).run
  end

  # rubocop:disable Metrics/AbcSize
  def update_page(id: nil, title: nil, version_number: nil, with:)
    id ||= get_page(title: title).id
    page = get_page(id: id)
    title ||= page.title
    version_number ||= page.version_number + 1
    with.merge!({ id: id, title: title, version_number: version_number })
    payload = Draft.new(self, with: with).payload
    query = Query.new(method: :put, uri: "/rest/api/content/#{id}", payload: payload)
    response = ConfluenceTask.new(query: query, profile: profile).run
    Page.new(@manager, response.body)
  end
  # rubocop:enable Metrics/AbcSize

  # LABEL METHODS:

  def get_page_labels(id: nil, title: nil)
    id ||= get_page(title: title).id
    query = Query.new(method: :get, uri: "/rest/api/content/#{id}/label")
    response = ConfluenceTask.new(query: query, profile: profile).run
    LabelSet.new(@manager, self, response.body['results'])
  end
end
