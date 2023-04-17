require "json"

abstract class LLM::CLI::Chat
  enum Role
    # Can be generated by the end users of an application, or set by a developer as an instruction.
    User
    # The system message helps set the behavior of the assistant.
    # GPT 3 does not always pay strong attention to system messages
    System
    # The assistant messages help store prior responses. They can also be written by a developer to help give examples of desired behavior.
    Assistant
  end

  struct Message
    include JSON::Serializable

    def initialize(@role : Role, @content : String)
    end

    getter role : Role
    getter content : String
  end

  alias Requirements = NamedTuple(
    name: String,
    requires: Array(String),
    optional: Array(String)?,
    help: String)

  abstract def chat(message : Array(Message)) : Message

  def send(message : String) : String
    chat([Message.new(:user, message)]).content
  end

  class Error < RuntimeError
  end

  macro finished
    class_getter service : LLM::CLI::Chat do
      selected = nil
      {{ LLM::CLI::Chat.subclasses }}.each do |klass|
        if selected = klass.meets_requirements?
          break
        end
      end

      raise Chat::Error.new("no LLM service is configured") unless selected
      selected
    end

    def self.requirements : Array(Requirements)
      requirements = [] of Requirements
      {{ LLM::CLI::Chat.subclasses }}.each do |klass|
        requirements << klass.requirements
      end
      requirements
    end
  end
end

require "./chat/*"
