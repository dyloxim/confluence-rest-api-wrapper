# frozen_string_literal: true

# documentation needed
class Draft
  attr_accessor :payload
  include ProfileLoader
  def initialize(profile_name, title, body)
    @profile_name = profile_name
    @payload = standard_payload
    @payload['title'] = title
    @payload['body']['storage']['value'] = body
  end

  def self.blank(profile)
    {
      'title' => '',
      'type' => 'page',
      'space' => { 'key' => profile.space },
      'body' => {
        'storage' => { 'value' => '', 'representation' => 'storage' }
      }
    }
  end
end
