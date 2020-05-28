# frozen_string_literal: true

# documentation needed
class Draft
  def initialize(manager, with: {})
    @manager = manager
    @payload = {
      title: '',
      type: 'page',
      space: { key: manager.space },
      body: {
        storage: { value: '', representation: 'storage' }
      }
    }
    with.each { |k, v| send("#{k}=", v) }
  end

  def payload
    @payload.to_json
  end

  def version_number=(num)
    @payload['version']['number'] = num.to_s
  end

  def title=(title)
    @payload['title'] = title
  end

  def body=(body)
    @payload['body'] = {
      storage: {
        value: body,
        representation: 'storage'
      }
    }
  end
end
