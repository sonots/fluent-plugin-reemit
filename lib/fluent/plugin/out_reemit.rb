module Fluent
  class ReemitOutput < Output
    Fluent::Plugin.register_output('reemit', self)

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
      $log.warn "reemit: #{e.class} #{e.message} #{e.backtrace.first}"
    end

    private

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
      Engine.matches.find {|m| ignore_self_match(m, tag) }
    end

    # Currently support only
    #
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
    def ignore_self_match(m, tag)
      return false if m.output == self
      return false if m.output.kind_of?(MultiOutput) and m.output.outputs.include?(self)
      m.match(tag)
    end
  end
end
