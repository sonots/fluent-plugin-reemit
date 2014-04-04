module Fluent
  class ReemitOutput < Output
    Fluent::Plugin.register_output('reemit', self)

    # To support log_level option implemented by Fluentd v0.10.43
    unless method_defined?(:log)
      define_method("log") { $log }
    end

    def initialize
      super
      @match_cache = {}
    end

    def configure(conf)
      super
    end

    def emit(tag, es, chain)
      engine_emit(tag, es)
      chain.next
    rescue => e
      log.warn "reemit: #{e.class} #{e.message} #{e.backtrace.first}"
    end

    # My Engine.emit
    def engine_emit(tag, es)
      target = @match_cache[tag]
      unless target
        target = engine_match(tag) || Fluent::EngineClass::NoMatchMatch.new
        @match_cache[tag] = target
      end
      target.emit(tag, es)
    end

    # My Engine.match
    def engine_match(tag)
      # @matches.find {|m| m.match(tag) } # original Engine.match
      Engine.matches.find {|m| match_without_self(m, tag) }
    end

    # <match foo.bar>
    #   type reemit
    # </match>
    #
    # and
    #
    # <match foo.bar>
    #   type copy
    #   <store>
    #     type reemit
    #   </store>
    # </match>
    def match_without_self(m, tag)
      return false if contain_self?(m.output)
      m.match(tag)
    end

    def contain_self?(output)
      if output.kind_of?(MultiOutput)
        output.outputs.each do |o|
          return true if contain_self?(o)
        end
      else
        return true if output == self
      end
      false
    end
  end
end
