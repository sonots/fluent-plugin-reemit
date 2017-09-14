require 'fluent/version'
if Fluent::VERSION > '0.12'
  require 'fluent/event_router'
end

module Fluent
  class ReemitOutput < Output
    Fluent::Plugin.register_output('reemit', self)

    # To support log_level option implemented by Fluentd v0.10.43
    unless method_defined?(:log)
      define_method("log") { $log }
    end

    def configure(conf)
      super

      major, minor, patch = Fluent::VERSION.split('.').map(&:to_i)
      if major > 0 || (major == 0 && minor >= 14)
        @router = V14EventRouter.new(self)
      elsif major == 0 && minor >= 12
        @router = V12EventRouter.new(self)
      else
        @router = V10EventRouter.new(self)
      end
    end

    def start
      super
    end

    def emit(tag, es, chain)
      @router.emit_stream(tag, es)
      chain.next
    rescue => e
      log.warn "reemit: #{e.class} #{e.message} #{e.backtrace.first}"
    end

    def included?(collector)
      return false if collector.nil?
      if collector == self
        true
      elsif collector.respond_to?(:outputs) # MultiOutput
        collector.outputs.each do |o|
          return true if self.included?(o)
        end
        false
      else
        false
      end
    end

    class V12EventRouter
      def initialize(reemit)
        @reemit = reemit
        @event_router = Engine.root_agent.event_router
        @chain = @event_router.instance_variable_get(:@chain) # only v0.12
        @emit_error_handler = @event_router.emit_error_handler
        @match_rules = @event_router.instance_variable_get(:@match_rules)
        @default_collector = @event_router.default_collector
        # @match_cache = @event_router.match_cache
        @match_cache = EventRouter::MatchCache.new # need to use a different cache
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
              if rule.collector.is_a?(Filter)
                pipeline ||= EventRouter::Pipeline.new
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

    # Almost same as V12EventRouter but it must call #emit_events instead of #emit.
    class V14EventRouter < V12EventRouter
      # copy from fluentd
      def emit_stream(tag, es)
        match(tag).emit_events(tag, es)
      rescue => e
        @emit_error_handler.handle_emits_error(tag, es, e)
      end
    end

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
