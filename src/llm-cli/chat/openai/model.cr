require "json"

module LLM::CLI::OpenAI
  struct List(Type)
    include JSON::Serializable

    getter object : String
    getter data : Array(Type)
  end

  struct Usage
    include JSON::Serializable

    def initialize(@total_tokens, @prompt_tokens, @completion_tokens)
    end

    getter total_tokens : Int64
    getter prompt_tokens : Int64
    getter completion_tokens : Int64
  end

  # GET https://api.openai.com/v1/models
  struct Model
    include JSON::Serializable
    include JSON::Serializable::Unmapped

    getter id : String
    getter object : String
    getter owned_by : String

    # Serializable::Unmapped
    # permission: [...]
  end
end
