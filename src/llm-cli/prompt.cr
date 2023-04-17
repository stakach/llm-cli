class LLM::CLI::Prompt
  def initialize(constraints : Enumerable(String) = [] of String)
    @constraints = constraints.to_a.map!(&.to_s)
  end

  property name : String = "Command Line Helper"
  property description : String = "an AI designed to autonomously construct and run cli commands"
  getter constraints : Array(String)
  getter goals : Array(String) = [] of String

  def add_constraint(constraint : String)
    constraints << constraint
  end

  def add_constraint(constraint : Array(String))
    constraints.concat constraint
  end

  def add_goal(goal : String)
    @goals.concat goal.split(/then|\.\s/i).map!(&.strip).reject!(&.empty?)
  end

  def add_goal(goal : Array(String))
    goal.each { |g| add_goal g }
  end

  def response_format
    {
      thoughts: {
        text:      "thought",
        reasoning: "reasoning",
        plan:      ["- short bulleted", "- list that conveys", "- long-term plan"],
        criticism: "constructive self-criticism",
        speak:     "thoughts summary to say to user",
      },
      commands: [
        {
          description: "description of what this command does",
          command:     "command parameter %{parameter placeholder}",
        },
      ],
    }
  end

  def generate_list(list : Enumerable(String))
    String.build do |str|
      list.each_with_index do |item, index|
        (index + 1).to_s(str)
        str << ". "
        str << item
        str << "\n"
      end
    end
  end

  def generate
    <<-PROMPT
      You are #{name}, #{description}.
      Your decisions must always be made independently without seeking user assistance. Play to your strengths as an LLM and pursue simple strategies with no legal complications.

      GOALS:
      
      #{generate_list goals}
      CONSTRAINTS:

      #{generate_list constraints}
      You should only respond in JSON format as described below
      Response Format:
      #{response_format.to_json}
      Ensure the response can be parsed by Python json.loads
    PROMPT
  end
end

require "./prompt/*"
