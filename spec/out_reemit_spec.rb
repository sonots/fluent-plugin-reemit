# encoding: UTF-8
require_relative 'spec_helper'

describe Fluent::ReemitOutput do
  before { Fluent::Test.setup }
  def create_driver(config, tag = 'test')
    Fluent::Test::OutputTestDriver.new(Fluent::CopyOutput, tag).configure(config)
  end

  describe '#contain_self?' do
    it 'should contain self' do
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
      reemit.contain_self?(output).should be_true
    end

    it 'should not contain self' do
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
      reemit.contain_self?(output).should be_false
    end

    it 'should contain self in deep' do
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
      reemit.contain_self?(output).should be_true
    end
  end
end
