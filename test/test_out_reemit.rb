require_relative 'helper'
require 'fluent/plugin/out_copy'
if Fluent::VERSION > '0.14'
  require 'fluent/test/driver/multi_output'
end

class ReemitOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  def create_driver(config, tag = 'test')
    if Fluent::VERSION > '0.14'
      Fluent::Test::Driver::MultiOutput.new(Fluent::Plugin::CopyOutput).configure(config)
    else
      Fluent::Test::OutputTestDriver.new(Fluent::CopyOutput, tag).configure(config)
    end
  end

  # THIS TEST IS ABSOLUTELY NOT ENOUGH. INSTEAD, RUN
  # bundle exec fluentd -c examples/reemit.conf
  sub_test_case "#include?" do
    test 'should be included' do
      config = %[
        <store>
          type reemit
        </store>
        <store>
          type stdout
        </store>
      ]
      output = create_driver(config).instance
      reemit = output.outputs.first
      assert { reemit.included?(output) }
    end

    test 'should not be included' do
      reemit_config = %[
        <store>
          type reemit
        </store>
        <store>
          type stdout
        </store>
      ]
      noreemit_config = %[
        <store>
          type stdout
        </store>
      ]
      reemit = create_driver(reemit_config).instance.outputs.first
      output = create_driver(noreemit_config).instance
      assert { ! reemit.included?(output) }
    end

    test 'should be included in deep' do
      config = %[
        <store>
          type stdout
        </store>
        <store>
          type copy
          <store>
            type stdout
          </store>
          <store>
            type reemit
          </store>
        </store>
      ]
      output = create_driver(config).instance
      reemit = output.outputs[1].outputs[1]
      assert { reemit.included?(output) }
    end
  end
end
