# encoding: UTF-8
require_relative 'spec_helper'
require 'fluent/plugin/out_copy'
if Fluent::VERSION > '0.14'
  require 'fluent/test/driver/multi_output'
end

describe Fluent::ReemitOutput do
  before { Fluent::Test.setup }
  def create_driver(config, tag = 'test')
    if Fluent::VERSION > '0.14'
      Fluent::Test::Driver::MultiOutput.new(Fluent::Plugin::CopyOutput).configure(config)
    else
      Fluent::Test::OutputTestDriver.new(Fluent::CopyOutput, tag).configure(config)
    end
  end

  # THIS TEST IS ABSOLUTELY NOT ENOUGH. INSTEAD, RUN
  # bundle exec fluentd -c examples/reemit.conf
  describe '#included?' do
    it 'should be included' do
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
      expect(reemit.included?(output)).to be_truthy
    end

    it 'should not be included' do
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
      expect(reemit.included?(output)).to be_falsy
    end

    it 'should be included in deep' do
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
      expect(reemit.included?(output)).to be_truthy
    end
  end
end
