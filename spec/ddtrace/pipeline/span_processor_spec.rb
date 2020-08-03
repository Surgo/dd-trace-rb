require 'spec_helper'
require 'ddtrace/pipeline'
require 'ddtrace/span'

RSpec.describe Datadog::Pipeline::SpanProcessor do
  def generate_span(name, parent = nil)
    Datadog::Span.new(nil, name).tap do |span|
      span.parent = parent
    end
  end

  let(:span_a) { generate_span('a') }
  let(:span_b) { generate_span('b') }
  let(:span_c) { generate_span('c') }
  let(:span_list) { [span_a, span_b, span_c] }

  context 'with no processing behavior' do
    subject(:span_processor) { described_class.new { |_| } }

    it 'should not modify any spans' do
      expect(subject.call(span_list)).to eq(span_list)
    end
  end

  context 'with processing behavior that returns falsey value' do
    subject(:span_processor) { described_class.new { |_| false } }

    it 'should not drop any spans' do
      expect(subject.call(span_list)).to eq(span_list)
    end
  end

  context 'with processing applied to spans' do
    subject(:span_processor) do
      described_class.new do |span|
        span.name += '!'
      end
    end

    it 'should modify spans according to processor criteria' do
      expect(subject.call(span_list).map(&:name)).to eq(['a!', 'b!', 'c!'])
    end
  end

  context 'with processing that raises an exception' do
    subject(:span_processor) do
      described_class.new do |span|
        span.name += '!'
        raise('Boom')
      end
    end

    it 'should modify spans according to processor criteria and catch exceptions' do
      expect(subject.call(span_list).map(&:name)).to eq(['a!', 'b!', 'c!'])
    end
  end
end
