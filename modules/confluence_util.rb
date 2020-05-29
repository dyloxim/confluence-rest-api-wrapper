# frozen_string_literal: true

# static methods for dealing with confluence objects
module ConfluenceUtil
  def self.parse_expand_attributes(attributes)
    attributes ||= []
    attributes += config['default_expand_attributes']
    attributes.map! do |attribute|
      {
        'version' => 'version',
        'body' => 'body.storage',
        'restrictions' => 'restrictions.read.restrictions.user,'\
        'restrictions.read.restrictions.group,'\
        'restrictions.update.restrictions.user,'\
        'restrictions.update.restrictions.group'
      }[attribute]
    end.join(',')
  end
end
