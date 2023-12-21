require 'faraday'

class Chatwoot::SendToBotpress < Micro::Case
  attributes :event
  attributes :botpress_endpoint
  attributes :botpress_bot_id

  def call!
    conversation_id = event['conversation']['id']
    url = "#{botpress_endpoint}/api/v1/bots/#{botpress_bot_id}/converse/#{conversation_id}"

    body = {
      'type': 'text',
      'metadata': {
        'event': event
      }
    }

    if event['event'] == 'message_updated' &&
       event['content_type'] == 'input_select' &&
       event['content_attributes'].key?('submitted_values')
      submitted_values = event['content_attributes']['submitted_values']
      if submitted_values.is_a?(Array) && !submitted_values.empty?
        # Assuming that 'Title' is always present in the first element of 'submitted_values' array
        body['text'] = submitted_values[0]['title']
      else
        # Handle the case where 'submitted_values' is empty or not an array
        Failure result: { message: 'Invalid submitted_values' }
      end
    else
      # For other events, use the original message content
      body['text'] = event['content']
    end

    response = Faraday.post(url, body.to_json, { 'Content-Type': 'application/json' })

    Rails.logger.info("Botpress response")
    Rails.logger.info("Status code: #{response.status}")
    Rails.logger.info("Body: #{response.body}")

    if response.status == 200
      Success result: JSON.parse(response.body)
    elsif response.status == 404 && response.body.include?('Invalid Bot ID')
      Failure result: { message: 'Invalid Bot ID' }
    else
      Failure result: { message: 'Invalid botpress endpoint' }
    end
  end
end
