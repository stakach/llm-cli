require "http"
require "../chat"
require "./openai/*"

class LLM::CLI::OpenAI::GPT < LLM::CLI::Chat
  def self.requirements : Requirements
    {
      name:     "OpenAPI GPT",
      requires: [%(ENV["OPENAI_API_KEY"])],
      optional: [%(ENV["OPENAI_API_ORG"])],
      help:     "https://help.openai.com/en/articles/4936850-where-do-i-find-my-secret-api-key",
    }
  end

  def self.meets_requirements?
    if api_key = ENV["OPENAI_API_KEY"]?
      api_org = ENV["OPENAI_API_ORG"]?
      return OpenAI::GPT.new(api_key, api_org)
    end
    nil
  end

  def initialize(@openai_key : String, @openai_org : String? = nil)
  end

  protected def client
    uri = URI.parse("https://api.openai.com")
    client = HTTP::Client.new(uri)
    client.before_request do |request|
      openai_org = @openai_org
      request.headers["Authorization"] = "Bearer #{@openai_key}"
      request.headers["OpenAI-Organization"] = openai_org if openai_org
      request.headers["Content-Type"] = "application/json"
    end
    client.connect_timeout = 5
    client.read_timeout = 120
    client.write_timeout = 30
    client
  end

  # lazily select the best model for the job
  getter model_id : String do
    response = client.get("/v1/models")
    models = List(Model).from_json(response.body).data.map(&.id)
    preferred = {model_preference, "gpt-4", "gpt-3.5-turbo"}

    found = preferred.last
    preferred.each do |model|
      next unless model.presence

      if models.includes?(model)
        found = model
        break
      end
    end
    found
  end

  # implement the primary interface
  def chat(message : Array(Message)) : Message
    chat = CreateChatCompletion.new(model_id, message)
    response = client.post("/v1/chat/completions", body: chat.to_json)
    raise "unexpected response #{response.status_code}\n#{response.body}" unless response.success?
    chat = ChatCompletion.from_json response.body
    chat.choices.first.message
  end
end
