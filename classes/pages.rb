# frozen_string_literal: true

# documentation needed
class PageSet
  include Enumerable
  include ProfileLoader
  attr_accessor :pages
  def initialize(calling_profile_name, json: nil, pages: nil)
    @profile_name = calling_profile_name
    if !json.nil?
      @pages = Maybe(json.body['results']).or_else([]).map do |page_json|
        Page.new(page_json, calling_profile_name)
      end
    elsif !pages.nil?
      @pages = pages
    end
  end

  def to_s
    puts "PAGESET INFO - pages: #{@pages.length}, first_id: #{@pages.first.id}, first_title: #{@pages.first.title}"
  end

  def empty?
    @pages.empty?
  end

  def +(other)
    these_pages = @pages
    other.each do |page|
      these_pages << page
    end
    PageSet.new(@profile_name, pages: these_pages)
  end

  def each
    @pages.each { |page| yield page }
  end

  def discard(page)
    @pages.delete(page)
    @pages
  end

  def async_each
    @pages.each { |page| Thread.new { yield page } }
  end

  def map
    new_pages = []
    @pages.each do |page|
      new_pages << yield(page)
    end
    @pages = new_pages
  end

  def async_map
    threads = []
    @pages.map do |label|
      Thread.new { threads << yield(label) }
    end
    @pages.map(&:value)
  end

  def length
    @pages.length
  end
end

# abstracts the json response objects recieved from the confluence api
class Page
  attr_reader :title, :body
  include ProfileLoader
  def initialize(page_json, calling_profile_name)
    @profile_name = calling_profile_name
    @id = page_json['id']
    @title = page_json['title']
    @body = page_json['body']
  end

  def to_s
    instance_variables.each do |ivar|
      puts "#{ivar}: #{instance_variable_get(ivar)}"
    end
  end

  def version_number
    query = Query.new(
      method: :get,
      uri: "/rest/api/content/#{@id}",
      headers: { expand: 'version.number' }
    )
    response = ConfluenceTask.new(query: query, profile: profile).run
    response.body['version']['number']
  end

  def labels
    query = Query.new(method: :get, uri: "/rest/api/content/#{@id}/label")
    response = ConfluenceTask.new(query: query, profile: profile).run
    LabelSet.new(@profile_name, self, response.body['results'])
  end

  def labels=(label_names)
    return unless LabelSet.valid(label_names)

    labels.clear
    labels << label_names
    labels
  end

  def delete
    query = Query.new(
      method: :delete,
      uri: "/rest/api/content/#{@id}"
    )
    ConfluenceTask.new(query: query, profile: profile).run
  end

  def title=(new_title)
    payload = standard_payload
    payload['title'] = new_title
    query = Query.new(
      method: :put,
      uri: "/rest/api/content/#{@id}",
      payload: payload,
      headers: { content_type: 'application/json' }
    )
    response = ConfluenceTask.new(query: query, profile: profile).run
    Page.new(response.body, @profile_name)
  end

  def children
    query = Query.new(
      method: :get,
      uri: "/rest/api/content/#{@id}/child/page"
    )
    response = ConfluenceTask.new(query: query, profile: profile).run
    PageSet.new(@profile_name, json: response)
  end

  def ancestors
    # recurses through all children... a bit hard to understand
    these_ancestors = PageSet.new(@profile_name, pages: [self])
    these_children = children
    return these_ancestors if these_children.empty?

    these_children.each do |child|
      these_ancestors += child.ancestors
    end
    these_ancestors
  end

  def body=(new_body)
    payload = Draft.new(@profile_name, with: { 'body' => new_body })
    query = Query.new(
      method: :put,
      uri: "/rest/api/content/#{@id}",
      payload: payload, headers: { content_type: 'application/json' }
    )
    response = ConfluenceTask.new(query: query, profile: profile).run
    Page.new(response.body, @profile_name)
  end

  def restrictions; end
end
