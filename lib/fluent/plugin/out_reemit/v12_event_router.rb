require 'fluent/filter'
require 'fluent/event_router'

module Fluent
  class ReemitOutput < Output
    class V12EventRouter
      def filter_class
        ::Fluent::Filter
      end

      def initialize(reemit)
        @reemit = reemit
        @event_router = Engine.root_agent.event_router
        @chain = @event_router.instance_variable_get(:@chain) # only v0.12
        @emit_error_handler = @event_router.emit_error_handler
        @match_rules = @event_router.instance_variable_get(:@match_rules)
        @default_collector = @event_router.default_collector
        # @match_cache = @event_router.match_cache
        @match_cache = ::Fluent::EventRouter::MatchCache.new # need to use a different cache
      end

      # copy from fluentd
      def emit_stream(tag, es)
        match(tag).emit(tag, es, @chain)
      rescue => e
        @emit_error_handler.handle_emits_error(tag, es, e)
      end

      # copy from fluentd
      def match(tag)
        collector = @match_cache.get(tag) {
          c = find(tag) || @default_collector
        }
        collector
      end

      def find(tag)
        # We want to reemit messages to the **next** `<match>`
        pipeline = nil
        found_reemit = false
        @match_rules.each_with_index { |rule, i|
          # if rule.match?(tag) # this is the original
          if rule.match?(tag)
            if found_reemit && !@reemit.included?(rule.collector)
              if rule.collector.is_a?(filter_class)
                pipeline ||= ::Fluent::EventRouter::Pipeline.new
                pipeline.add_filter(rule.collector)
              else
                if pipeline
                  pipeline.set_output(rule.collector)
                else
                  # Use Output directly when filter is not matched
                  pipeline = rule.collector
                end
                return pipeline
              end
            elsif !found_reemit && @reemit.included?(rule.collector)
              found_reemit = true
            end
          end
        }

        if pipeline
          # filter is matched but no match
          pipeline.set_output(@default_collector)
          pipeline
        else
          nil
        end
      end
    end
  end
end
