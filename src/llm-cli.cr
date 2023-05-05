require "spinner"
require "colorize"
require "./llm-cli/*"
require "option_parser"

# check for any runtime flags
args = ARGV.dup
verbose = false
is_query = false
model = ENV["LLM_MODEL"]? || ""

# Command line options
OptionParser.parse(args) do |parser|
  parser.on("-m MODEL", "--model=MODEL", "specify a LLM model to use") do |llm_model|
    model = llm_model
  end

  parser.on("-q", "--query", "Just ask a question of the LLM and return the response") do
    is_query = true
  end

  parser.on("-v", "--verbose", "Output all the request and response data") do
    verbose = true
  end

  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit 0
  end
end

# init the service
shell = LLM::CLI::Shell.new
spin = Spin.new
chat = begin
  LLM::CLI::Chat.service
rescue error : LLM::CLI::Chat::Error
  puts error.message.colorize(:red)
  LLM::CLI::Chat.requirements.each do |req|
    puts "\n#{req[:name]}"
    puts "env vars:\n - #{req[:requires].join("\n - ")}"
    optional = req[:optional]
    puts " - #{optional.map { |opt| "#{opt} (optional)" }.join("\n - ")}" if optional && !optional.empty?
    puts req[:help]
  end
  exit 1
end

chat.model_preference = model
puts "> Model Selected: #{chat.model_id}".colorize(:red) if verbose

# we want to ask some questions via the command line
if is_query && (question = args.join("").presence)
  begin
    messages = [LLM::CLI::Chat::Message.new(LLM::CLI::Chat::Role::User, question)]
    loop do
      spin.start
      response = chat.chat messages
      messages << response
      spin.stop

      puts "\n#{response.content}\n".colorize(:green)

      question = shell.get_input("reply? ").strip
      exit 0 unless question.presence
      messages << LLM::CLI::Chat::Message.new(LLM::CLI::Chat::Role::User, question)
    end
  rescue error
    spin.stop
    puts error.inspect_with_backtrace.colorize(:red)
    exit 2
  end
end

prompt = LLM::CLI::Prompt.new({
  "No user assistance, command ordering is important",
  "You are running on #{shell.operating_system}",
  "The current shell is: #{File.basename shell.selected}",
  "Wrap unknown command parameters in <brackets>",
  "you might need to change directory before executing subsequent commands",
  "a single command might solve multiple goals, be creative",
})

# grab the users request
request = args.join(" ").presence
unless request
  puts "No command description provided".colorize(:red)
  exit 1
end
prompt.add_goal request

prompt_message = prompt.generate
puts "> Requesting:\n#{prompt_message}\n".colorize(:red) if verbose

begin
  spin.start
  # query the configured LLM
  response = chat.send prompt_message
  spin.stop

  puts "> Raw response:\n#{response}\n".colorize(:red) if verbose

  # process the response
  begin
    cmds = LLM::CLI::Prompt::Response.from_json response
    if cmds.empty?
      puts "Failed to generate commands:".colorize(:red)
      puts (cmds.speak.presence || cmds.criticism.presence || cmds.text).colorize(:red)
      exit 0
    end

    # provide the user feedback
    puts (cmds.speak.presence || cmds.text).colorize(:dark_gray)
    if criticism = cmds.criticism.presence
      puts "  - NOTE: #{criticism}".colorize(:dark_gray)
    end

    # execute commands
    pattern = /<(?P<content>[a-zA-Z0-9_\-\ ]+)>|%\{(?<content>[^}]+)\}/
    previous = {} of String => String
    puts "Commands:".colorize(:dark_gray)
    cmds.each do |cmd|
      puts " > #{cmd.command}".colorize(:dark_gray)
    end

    cmds.each do |cmd|
      # prompt user for any required substitutions
      current = {} of String => Tuple(String, String)

      puts "\n#{cmd.description}".colorize(:green)
      puts "preparing: #{cmd.command}".colorize(:dark_gray)

      cmd.command.scan(pattern).each do |match_data|
        match = match_data["content"].to_s
        next if current[match]?

        input = if default = previous[match]?
                  shell.get_input("#{match} [#{default}]: ").presence || default
                else
                  shell.get_input("#{match}: ")
                end

        current[match] = {match_data[0], input}
        previous[match] = input
      end

      execute = cmd.command
      current.each do |_match, (sub, replacement)|
        execute = execute.gsub(sub, replacement)
      end

      # execute the command
      puts execute.colorize(:dark_gray)
      do_exec = shell.get_input("execute [Y]? ").presence
      if do_exec.nil? || do_exec.try(&.matches?(/^(y|Y)/))
        status = Process.new(
          shell.selected,
          {"-c", execute},
          input: :inherit,
          output: :inherit,
          error: :inherit
        ).wait
        puts "Command failed with exit code: #{status.exit_code}" unless status.success?

        # change directory as required
        if execute.starts_with?("cd ") || execute.includes?("&& cd ")
          args = Process.parse_arguments(execute)
          found = nil
          args.each_with_index do |cmd, index|
            if cmd == "cd"
              found = index + 1
              break
            end
          end
          if found && (new_dir = args[found]?)
            Dir.cd(new_dir)
          end
        end
      end
    end
  rescue error
    puts error.inspect_with_backtrace.colorize(:red)
    puts "response was:\n#{response.colorize(:yellow)}"
    exit 3
  end
rescue error
  spin.stop
  puts error.inspect_with_backtrace.colorize(:red)
  exit 2
end
