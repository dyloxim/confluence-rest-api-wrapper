# frozen_string_literal: true

# !!
class LabelSet
  include Enumerable
  include ProfileLoader
  attr_accessor :labels
  def initialize(caller_profile_name, page, labels_hash)
    @page = page
    @profile_name = caller_profile_name
    @labels = labels_hash.map do |label_hash|
      Label.new(@profile_name, page.id, label_hash: label_hash)
    end
  end

  def self.valid?(label_names)
    verdict = true
    label_names.each { |name| verdict = false if name =~ /\s/ }
    puts 'ERROR: no spaces allowed in label names' if verdict == false
    verdict
  end

  def has?(label_name)
    verdict = false
    @labels.each do |label|
      verdict = true if label.name == label_name
    end
    verdict
  end

  def label_payload(label_name)
    { 'prefix': 'global', 'name': label_name }
  end

  def valid_label(label_name)
    if label_name !~ /\s/
      true
    else
      puts 'ERROR: labels must not contain spaces'
    end
  end

  def upload_label(label_name)
    query = Query.new(
      method: :post,
      uri: "/rest/api/content/#{@page.id}/label",
      payload: label_payload(label_name),
      headers: { content_type: 'application/json' }
    )
    ConfluenceTask.new(query: query, profile: profile).run
  end

  def add_label(label_name)
    upload_label(label_name)
    new_label = Label.new(@profile_name, @page.id, label_name: label_name)
    @labels << new_label unless has?(label_name)
    new_label
  end

  def <<(label_arr)
    threads = []
    label_arr.each do |label_name|
      threads << Thread.new { add_label(label_name) }
    end
    threads.map(&:value)
  end

  def clear
    async_each(&:remove)
    @labels = []
  end

  def each
    @labels.each { |label| yield(label) }
  end

  def async_each
    threads = []
    @labels.each { |label| threads << Thread.new { yield label } }
    threads.map(&:value)
  end

  def map
    @labels.map do |label|
      yield(label)
    end
  end

  def async_map
    threads = []
    @labels.map do |label|
      Thread.new { threads << yield(label) }
    end
    @labels.map(&:value)
  end
end

# does what it does
class Label
  include ProfileLoader
  attr_accessor :name, :prefix, :label_id, :page_id
  def initialize(profile_name, page_id, label_name: '', label_hash: {})
    @profile_name = profile_name
    @page_id = page_id
    if label_name == ''
      process_json(label_hash)
    else
      @prefix = 'global'
      @name = label_name
    end
  end

  def process_json(label_hash)
    @prefix = label_hash['prefix']
    @name = label_hash['name']
    @label_id = label_hash['id']
  end

  def remove
    query = Query.new(
      method: :delete,
      uri: "/rest/api/content/#{@page_id}/label",
      headers: { name: @name }
    )
    ConfluenceTask.new(query: query, profile: profile).run
  end
end
