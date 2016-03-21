module Serverspec::Type
  class ATDDMemcache < Base
    def stdout
      command_result.stdout
    end

    def stderr
      command_result.stderr
    end

    def exit_status
      command_result.exit_status.to_i
    end

    private
    def command_result()
      @command_result ||= @runner.run_command("/ansible-tdd/memclient "+ @name)
    end

  end
  def memcached(paths)
    ATDDMemcache.new(paths)
  end
end

include Serverspec::Type