require_relative 'v12_event_router'

module Fluent
  class ReemitOutput < Output
    # Almost same as V12EventRouter but
    # (1) it must call #emit_events instead of #emit
    # (2) Filter class is Fluent::Plugin::Filter instead of Fluent::Filter
    class V14EventRouter < V12EventRouter
      def filter_class
        ::Fluent::Plugin::Filter
      end

      # copy from fluentd
      def emit_stream(tag, es)
        match(tag).emit_events(tag, es)
      rescue => e
        @emit_error_handler.handle_emits_error(tag, es, e)
      end
    end
  end
end
