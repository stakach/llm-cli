struct LLM::CLI::Prompt::Response
  include JSON::Serializable

  struct Thoughts
    include JSON::Serializable

    getter text : String
    getter reasoning : String?
    # GPT3.5 sometimes returns an array
    getter plan : String | Array(String)?
    getter criticism : String?
    getter speak : String?
  end

  struct Command
    include JSON::Serializable

    getter description : String
    getter command : String
  end

  getter thoughts : Thoughts
  getter commands : Array(Command)

  delegate empty?, each, to: @commands
  delegate text, reasoning, criticism, speak, to: @thoughts

  def plan
    plan = thoughts.plan
    points = case plan
             in String
               [plan]
             in Array(String)
               plan
             in Nil
               [] of String
             end
    points.join("\n")
  end
end
