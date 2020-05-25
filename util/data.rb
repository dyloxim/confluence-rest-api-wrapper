# frozen_string_literal: true

# general purpose stuff
module Util
  # finds every value in an enumerable list which is repeated and returns those values
  def self.dupes(enumerable)
    h = Hash.new(0)
    enumerable.find_all { |each| (h[each] += 1) == 2 }
  end

  # for converting an array of hashes into a single hash
  # code ripped from:
  # `https://stackoverflow.com/questions/5490952/how-to-merge-array-of-hashes-to-get-hash-of-arrays-of-values`
  def self.collect_values(hash_array)
    hash_with_array_wrapped_values = hash_array.map(&:to_a).flatten(1).each_with_object({}) { |(k, v), h| (h[k] ||= []) << v; }
    Hash[hash_with_array_wrapped_values.map { |k, v| [k, v[0]] }]
  end

  def self.has?(hash, pairs)
    verdict = true
    pairs.each do |key, value|
      verdict = false if hash[key] != value
    end
    verdict
  end

  def self.just(hash, keep_keys)
    hash.dup.keep_if { |col, _val| keep_keys.include?(col) }
  end

  def self.just!(hash, keep_keys)
    hash.keep_if { |col, _val| keep_keys.include?(col) }
  end

  def self.except(hash, reject_keys)
    hash.dup.keep_if { |col, _val| !reject_keys.include?(col) }
  end
end

# top level docs
class DataSet
  include Enumerable
  include Util
  def initialize(hash_array)
    @rows = hash_array
  end

  def values
    @rows
  end

  def to_s
    puts @rows
  end

  def first
    @rows.first
  end

  def <<(other)
    @rows << other
  end

  def just_column(column_name)
    just_columns([column_name])
  end

  def just_columns(column_names)
    new_rows = []
    @rows.each do |row|
      new_rows << Util.just(row, column_names)
    end
    DataSet.new(new_rows)
  end

  def except_column(column_name)
    except_columns([column_name])
  end

  def except_columns(column_names)
    new_rows = []
    @rows.each do |row|
      new_rows << Util.except(row, column_names)
    end
    DataSet.new(new_rows)
  end

  def where(pairs)
    new_rows = []
    @rows.each do |row|
      checks_out = true
      pairs.each do |key, expected|
        checks_out = false if row[key] != expected
      end
      new_rows << row if checks_out
    end
    DataSet.new(new_rows)
  end

  def uniq
    DataSet.new(@rows.uniq)
  end

  def uniq_in_column(column_name)
    DataSet.new(column(column_name).uniq)
  end

  def uniq_in_columns(column_names)
    DataSet.new(columns(column_names).uniq)
  end

  def gather
    @rows = collect_values(@rows)
  end

  def keep_if(&block)
    @rows.keep_if { |element| block.call(element) }
    DataSet.new(@rows)
  end

  def each(&block)
    @rows.each { |element| block.call(element) }
    DataSet.new(@rows)
  end

  def map(&block)
    result = []
    @rows.each { |element| result << block.call(element) }
    DataSet.new(result)
  end
end

# a hash describing the two different mappings that can exist between pairs of data
# as passed to the function in the form of a hash
#
# NOTE:
# (Reflections on a previus naming system -> changes proposed here were carried
# forward)
# on terminology; I have called points which map to more than one value 'surjective
# points'. In retrospect I think that this is not the best terminology that I could
# have used. A function is surjective if the same destination point is hit by multiple
# departure points. a mapping where a single departure point is paired with multiple
# destination points is not a function at all.
#
# With this in mind I wonder if I should have called them 'well defined' points vs.
# 'undefined' points or something to that effect.
class Relation
  def initialize(hash_array)
    @table = DataSet.new(validate_hash(hash_array))
    @left_set = @table.first.keys[0]
    @right_set = @table.first.keys[1]
  end

  def directions
    [
      { departure_set: @left_set, arrival_set: @right_set },
      { departure_set: @right_set, arrival_set: @left_set }
    ]
  end

  def validate_hash(hash_array)
    valid = true
    hash_array.each { |row| valid = false if row.keys.length != 2 }
    valid ? hash_array.uniq : []
  end

  def related(direction, point)
    @table.where(point).map { |pair| pair[direction[:arrival_set]] }.values
  end

  def as_map
    summary = DataSet.new([])
    directions.each do |dir|
      set_name = dir[:departure_set]
      map_info = dir
      map_def = {}
      @table.just_column(set_name).uniq.each do |dep_point|
        map_def[dep_point[set_name]] = related(dir, dep_point)
      end
      map_info[:pointwise_definition] = map_def
      summary << map_info
    end
    summary
  end

  def categorise_points
    inputs = @table.just_column(@departure_set)
    undefined_points = Util.dupes(inputs)
    well_defined_points = inputs.dup.reject { |point| undefined_points.include?(point) }
    {
      well_defined: well_defined_points,
      undefined: undefined_points
    }
  end

  def summary(relation_table)
    signatures = map_signatures(relation_table)
    {
      "Summary of map: #{signatures[:forwards][:from]} -> #{signatures[:forwards][:to]}" =>
      verbose_map_from_relation(relation_table, signature: signatures[:forwards]),
      "Summary of map: #{signatures[:backwards][:from]} -> #{signatures[:backwards][:to]}" =>
      verbose_map_from_relation(relation_table, signature: signatures[:backwards])
    }
  end
end
