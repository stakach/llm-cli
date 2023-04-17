require "spinner"
require "colorize"
require "./llm-cli/*"

# init the service
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
shell = LLM::CLI::Shell.new
prompt = LLM::CLI::Prompt.new({
  "No user assistance",
  "Commands to be executed on the following shell: #{File.basename shell.selected}",
  "Wrap unknown command parameters in <brackets>",
})

# grab the users request
request = ARGV.dup.join(" ").presence
unless request
  puts "No command description provided".colorize(:red)
  exit 1
end
prompt.add_goal request

spin = Spin.new
begin
  spin.start
  # query the configured LLM
  response = chat.send prompt.generate
  spin.stop

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
