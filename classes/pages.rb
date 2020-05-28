# frozen_string_literal: true

# documentation needed
class PageSet
  include Enumerable
  attr_accessor :pages
  def initialize(manager, json: nil, pages: nil)
    @manager = manager
    if !json.nil?
      @pages = Maybe(json.body['results']).or_else([]).map do |page_json|
        Page.new(manager, page_json)
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
    PageSet.new(@manager, pages: these_pages)
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
  attr_reader :title, :id
  def initialize(manager, page_json)
    @manager = manager
    @id = page_json['id']
    @title = page_json['title']
    @body = Maybe(page_json['body'])['storage']['value'].or_else(nil)
    @version_number = Maybe(page_json['version'])['number'].or_else(nil)
  end

  def body
    # if a page is generated by using the cql search endpoint
    # of the confluence REST API, some of the attributes do not
    # 'expand' properly - so they need to be retrieved by
    # repeating the request on the REST endpoint specifically
    # corresponding to this page id.
    return @body unless @body.nil?

    this_page = @manager.get_page(id: @id)
    @version_number = this_page.version_number
    @body = this_page.body
  end

  def version_number
    # if a page is generated by using the cql search endpoint
    # of the confluence REST API, some of the attributes do not
    # 'expand' properly - so they need to be retrieved by
    # repeating the request on the REST endpoint specifically
    # corresponding to this page id.
    return @version_number unless @version_number.nil?

    this_page = @manager.get_page(id: @id)
    @version_number = this_page.version_number
  end

  def to_s
    instance_variables.each do |ivar|
      puts "#{ivar}: #{instance_variable_get(ivar)}"
    end
  end

  def labels
    manager.get_page_labels(id: @id)
  end

  def labels=(label_names)
    return unless LabelSet.valid(label_names)

    labels.clear
    labels << label_names
    labels
  end

  def delete
    manager.delete_page(id: @id)
  end

  def title=(new_title)
    manager.update_page(id: @id, with: { title: new_title })
  end

  def children
    query = Query.new(
      method: :get,
      uri: "/rest/api/content/#{@id}/child/page"
    )
    response = ConfluenceTask.new(query: query, profile: profile).run
    PageSet.new(@manager, json: response)
  end

  def ancestors
    # recurses through all children... a bit hard to understand
    these_ancestors = PageSet.new(@manager, pages: [self])
    these_children = children
    return these_ancestors if these_children.empty?

    these_children.each do |child|
      these_ancestors += child.ancestors
    end
    these_ancestors
  end

  def body=(new_body)
    @manager.update_page(id: @id, with: { body: new_body })
  end

  def restrictions; end
end
