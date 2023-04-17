class LLM::CLI::Shell
  AVAILABLE_SHELLS = File.read("/etc/shells").split("\n").map!(&.strip).reject!(&.starts_with?('#'))
  PREFERRED_SHELLS = {ENV["SHELL"]?, "/zsh", "/bash", "/sh"}

  # automatically select a shell to run commands in based on what's
  # available in the users environment
  getter selected : String do
    shell = AVAILABLE_SHELLS.first
    found = false
    PREFERRED_SHELLS.each do |preferred|
      preferred = preferred.presence
      next unless preferred

      AVAILABLE_SHELLS.each do |available|
        if available.ends_with?(preferred)
          found = true
          shell = available
        end
      end
      break if found
    end
    shell
  end

  def get_input(prompt)
    print prompt
    STDIN.gets.to_s.chomp
  end
end
