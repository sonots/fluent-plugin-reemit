module Fluent
  class ReemitOutput < Output
    class V10EventRouter
      def initialize(reemit)
        @reemit = reemit
        @matches = Engine.matches
        @match_cache = {}
      end

      def emit_stream(tag, es)
        target = @match_cache[tag]
        unless target
          target = match(tag) || Fluent::EngineClass::NoMatchMatch.new
          @match_cache[tag] = target
        end
        target.emit(tag, es)
      end

      def match(tag)
        # We want to reemit messages to the **next** `<match>`
        found_reemit = false
        @matches.find do |m|
          if m.match(tag)
            if found_reemit && !@reemit.included?(m.output)
              true
            elsif !found_reemit && @reemit.included?(m.output)
              found_reemit = true
              false
            end
          end
        end
      end
    end
  end
end
