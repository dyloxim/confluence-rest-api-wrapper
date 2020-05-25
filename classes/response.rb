# frozen_string_literal: true

# Secondary class to `ConfluenceTask` - helps organise things
class Response
  attr_accessor :status, :headers, :body
  def initialize(status, headers, body)
    @status = status
    @headers = headers
    @body_raw = body
    @body = process_body(body)
    log_response
  end

  def log_response
    if status != 200
      puts 'TASK INFO: response body nullified because status != 200'
      puts "RESPONSE MESSAGE: #{Maybe(body)['message'].or_else { 'no message' }}"
      body = ''
    end
    File.open(path(config['log_file']), 'a') do |f|
      f.puts erb('response-log', binding)
    end
  end

  def process_body(body)
    JSON.parse(body)
  rescue JSON::ParserError
    nil
  end
end
