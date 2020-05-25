# frozen_string_literal: true

# Purpose: extract this function out
# so it can be included in many other
# classes in a DRY way.
# Reason for original function:
# to stop credentials ever being
# stored in object instace properties -
# - the profile name is stored, but the
# details are always extracted from the
# configuration files.
module ProfileLoader
  def self.profile
    Profile.new(profile_details(@profile_name))
  end
end
