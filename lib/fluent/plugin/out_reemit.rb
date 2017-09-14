require 'fluent/version'

module Fluent
  class ReemitOutput < Output
    major, minor, patch = Fluent::VERSION.split('.').map(&:to_i)
    if major > 0 || (major == 0 && minor >= 14)
      require_relative 'out_reemit/v14_event_router'
      EventRouter = V14EventRouter
    elsif major == 0 && minor >= 12
      require_relative 'out_reemit/v12_event_router'
      EventRouter = V12EventRouter
    else
      require_relative 'out_reemit/v10_event_router'
      EventRouter = V10EventRouter
    end

    Fluent::Plugin.register_output('reemit', self)

    # To support log_level option implemented by Fluentd v0.10.43
    unless method_defined?(:log)
      define_method("log") { $log }
    end

    def configure(conf)
      super

      @router = EventRouter.new(self)
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
  end
end
