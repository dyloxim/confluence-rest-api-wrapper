# frozen_string_literal: true
# top level docs

# old unused methods
# def args_hash(caller_binding, method: method(caller_locations[0].label))
#   method
#     .parameters.map(&:last)
#     .map do |var|
#     [var, caller_binding.local_variable_get(var)]
#   end.to_h
# end
# def args_arr(caller_binding, method:)
#   args_hash(caller_binding, method: method).map do |name, value|
#     {
#       name: name,
#       value: value
#     }
#   end
# end
# def first_non_nil(arr)
#   index = 0
#   index += 1 until !arr[index][:value].nil? || index == arr.length - 1
#   arr[index]
# end
# def arg_select(caller_binding, method: method(caller_locations[0].label))
#   args = args_arr(caller_binding, method: method)
#   first_non_nil(args)
# end
