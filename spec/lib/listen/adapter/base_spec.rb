require 'spec_helper'

include Listen

describe Adapter::Base do
  class QueueOverflowError < RuntimeError; end

  class FakeAdapter < described_class
    def initialize(*args)
      super(*args)
    end

    def _run
      raise QueueOverflowError.new('Exception in Adapter')
    end
  end

  subject { FakeAdapter.new(mq: mq, directories: []) }

  let(:mq) { instance_double(Listener) }

  describe '#_notify_change' do
    let(:dir) { Pathname.pwd }

    context 'listener is listening or paused' do
      let(:worker) { instance_double(Change) }

      it 'calls change on change_pool asynchronously' do
        expect(mq).to receive(:_queue_raw_change).
          with(:dir, dir, 'path', recursive: true)

        subject.send(:_queue_change, :dir, dir, 'path', recursive: true)
      end
    end
  end

  describe 'start' do
    context 'Exception in Thread' do
      it 'will be reraised in Thread.main' do
        expect { subject.start; sleep 1 }.to raise_error(QueueOverflowError)
      end
    end
  end
end
