# frozen_string_literal: true

# documentation needed
class RestrictionSet
  include Enumerable
  attr_accessor :labels
  def initialize(manager, restrictions_hash, page: nil, page_id: nil)
    @manager = manager
    @page = page || @manager.get_page(id: page_id)
    @restrictions = process_restriction_json(restrictions_hash)
  end

  def process_restriction_json(json)
    results = []
    results << process_restrictions_with_properties('read', 'user', json)
    results << process_restrictions_with_properties('read', 'group', json)
    results << process_restrictions_with_properties('update', 'user', json)
    results << process_restrictions_with_properties('update', 'group', json)
    results.flatten
  end

  def process_restrictions_with_properties(action, user_type, json)
    results = []
    Maybe(json[action])['restrictions'][user_type]['results'].or_else({}).each do |read_restrictions|
      results << Restriction.new(
        @manager, @page.id,
        action: action,
        restriction_hash: read_restrictions
      )
    end
    results
  end

  def self.valid?(restriction_names)
    verdict = true
    restriction_names.each { |name| verdict = false if name =~ /\s/ }
    puts 'ERROR: no spaces allowed in restriction names' if verdict == false
    verdict
  end

  def has?(restriction_name)
    verdict = false
    @restrictions.each do |restriction|
      verdict = true if restriction.name == restriction_name
    end
    verdict
  end

  def valid_restriction(restriction_name)
    if restriction_name !~ /\s/
      true
    else
      puts 'ERROR: restrictions must not contain spaces'
    end
  end

  def add_restriction(restriction_name)
    upload_restriction(restriction_name)
    new_restriction = Restriction.new(@manager, @page.id, restriction_name: restriction_name)
    @restrictions << new_restriction unless has?(restriction_name)
    new_restriction
  end

  def <<(restriction_arr)
    threads = []
    restriction_arr.each do |restriction_name|
      threads << Thread.new { add_restriction(restriction_name) }
    end
    threads.map(&:value)
  end

  def clear
    async_each(&:remove)
    @restrictions = []
  end

  def each
    @restrictions.each { |restriction| yield(restriction) }
  end

  def async_each
    threads = []
    @restrictions.each { |restriction| threads << Thread.new { yield restriction } }
    threads.map(&:value)
  end

  def map
    @restrictions.map do |restriction|
      yield(restriction)
    end
  end

  def async_map
    threads = []
    @restrictions.map do |restriction|
      Thread.new { threads << yield(restriction) }
    end
    @restrictions.map(&:value)
  end
end

# documentation needed
class Restriction
  attr_accessor :name, :prefix, :restriction_id, :page_id
  def initialize(manager, page_id, action:, restriction_hash: {})
    @manager = manager
    @page_id = page_id
    @permitted_action = action
    process_json(restriction_hash)
  end

  def process_json(restriction_hash)
    @permittee = restriction_hash['username'] || restriction_hash['name']
    @user_type = {
      'known' => 'individual_user',
      'group' => 'user_group'
    }[restriction_hash['type']]
  end

  def remove
    query = Query.new(
      method: :delete,
      uri: "/rest/api/content/#{@page_id}/restriction",
      headers: { name: @name }
    )
    ConfluenceTask.new(query: query, profile: profile).run
  end
end

# the exact json structure confluence REST API is a bit perverse so having this
# class construct the object for you is much nicer than writing it out yourself
class RestrictionDraft
  attr_accessor :payload
  def initialize(user_type:, permittee:, permitted_action:)
    @payload = { operation: permitted_action, restrictions: { user: [], group: [] } }
    if user_type == 'individual_user'
      @payload[:restrictions][:user] << { type: 'known', username: permittee }
    elsif user_type == 'user_group'
      @payload[:restrictions][:group] << { type: 'group', name: permittee }
    end
    @payload = [] << @payload
  end
   # {"type":"page","space":{"key":"EE"},"restrictions":[{"operation":"update","restrictions":{"user":[{"type":"known","username":"js2610"}],"group":[]}}],"id":"201134122","title":"General","version":{"number":"3"}}

  def version_number=(num)
    @payload[:version] = { number: num.to_s }
  end

  def title=(title)
    @payload[:title] = title
  end

  def id=(id)
    @payload[:id] = id
  end

  def body=(body)
    @payload[:body] = {
      storage: {
        value: body,
        representation: 'storage'
      }
    }
  end
end
