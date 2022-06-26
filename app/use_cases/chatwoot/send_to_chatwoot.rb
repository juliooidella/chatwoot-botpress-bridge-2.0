require 'faraday'

class Chatwoot::SendToChatwoot < Micro::Case
  attributes :account_id
  attributes :conversation_id
  attributes :content

  attributes :chatwoot_endpoint
  attributes :chatwoot_bot_token

  def call!
    url = "#{chatwoot_endpoint}/api/v1/accounts/#{account_id}/conversations/#{conversation_id}/messages"

    body = {
      'content': content
    }

    response = Faraday.post(url, body.to_json, 
      {'Content-Type': 'application/json', 'api_access_token': "#{chatwoot_bot_token}"}
    )

    if (response.status == 200)
      Success result: JSON.parse(response.body)
    elsif (response.status == 404 && response.body.include?('Resource could not be found') )
      Failure result: { message: 'Chatwoot resource could not be found' }
    elsif (response.status == 404)
      Failure result: { message: 'Invalid chatwoot endpoint' }
    elsif (response.status == 401)
      Failure result: { message: 'Invalid chatwoot access token' }
    else
      Failure result: { message: 'Chatwoot server error' }
    end
  end
end