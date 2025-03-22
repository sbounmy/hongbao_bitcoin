require 'rails_helper'

RSpec.describe ApplicationService do
  before do
    # Reset class variable between tests
    ApplicationService.propagate = nil
  end

  # Test service with successful outcome
  before do
    class TestService < ApplicationService
      def call(test_param = nil)
        success(test_param || "test")
      end
    end

    # Test service that raises an exception
    class FailingService < ApplicationService
      class TestError < StandardError; end

      def call
        raise TestError, "Test error message"
      end
    end

    # Test service with optional parameters
    class ParameterizedService < ApplicationService
      def call(param1, param2: nil)
        success("#{param1} - #{param2}")
      end
    end
  end
  describe '.call' do
    context 'when the service succeeds' do
      it 'returns a successful response' do
        result = TestService.call

        expect(result).to be_success
        expect(result).not_to be_failure
        expect(result.payload).to eq("test")
        expect(result.error).to be_nil
      end

      it 'passes parameters to the service' do
        result = TestService.call("custom payload")

        expect(result.payload).to eq("custom payload")
      end

      it 'handles multiple parameters and keyword arguments' do
        result = ParameterizedService.call("value1", param2: "value2")

        expect(result.payload).to eq("value1 - value2")
      end
    end

    context 'when the service fails' do
      before do
        FailingService.propagate = false
      end

      it 'returns a failure response' do
        expect(ApplicationService::ErrorService).to receive(:error)

        result = FailingService.call

        expect(result).not_to be_success
        expect(result).to be_failure
        expect(result.payload).to be_nil
        expect(result.error).to be_a(FailingService::TestError)
        expect(result.error.message).to eq("Test error message")
      end
    end
  end

  describe '.call!' do
    context 'when the service succeeds' do
      it 'returns the success payload directly' do
        result = TestService.call!

        expect(result).to be_success
        expect(result.payload).to eq("test")
      end
    end

    context 'when the service fails' do
      it 'propagates the exception' do
        expect {
          FailingService.call!
        }.to raise_error(FailingService::TestError, "Test error message")
      end
    end
  end

  describe '#success' do
    it 'creates a successful response' do
      service = TestService.new
      response = service.success("payload")

      expect(response).to be_success
      expect(response).not_to be_failure
      expect(response.payload).to eq("payload")
      expect(response.error).to be_nil
    end

    it 'works with nil payload' do
      service = TestService.new
      response = service.success

      expect(response).to be_success
      expect(response.payload).to be_nil
    end
  end

  describe '#failure' do
    let(:exception) { StandardError.new("Error message") }

    context 'when propagate is false' do
      before do
        TestService.propagate = false
      end

      it 'creates a failure response' do
        service = TestService.new
        expect(ApplicationService::ErrorService).to receive(:error).with(exception, {})

        response = service.failure(exception)

        expect(response).not_to be_success
        expect(response).to be_failure
        expect(response.payload).to be_nil
        expect(response.error).to eq(exception)
      end

      it 'passes options to ErrorService' do
        service = TestService.new
        options = { context: 'test' }
        expect(ApplicationService::ErrorService).to receive(:error).with(exception, options)

        service.failure(exception, options)
      end
    end

    context 'when propagate is true' do
      before do
        TestService.propagate = true
      end

      it 'raises the exception' do
        service = TestService.new
        expect {
          service.failure(exception)
        }.to raise_error(StandardError, "Error message")
      end
    end
  end

  describe '#credentials' do
    it 'calls Rails.application.credentials.dig with the provided keys' do
      allow(Rails.application.credentials).to receive(:dig).with(:key1, :key2).and_return('secret')

      service = TestService.new
      result = service.credentials(:key1, :key2)

      expect(result).to eq('secret')
    end
  end

  # Test Response struct
  describe 'Response' do
    it 'has success? accessor' do
      response = ApplicationService::Response.new(true, "payload")
      expect(response.success?).to eq(true)
    end

    it 'has failure? method that is the opposite of success?' do
      success_response = ApplicationService::Response.new(true, "payload")
      failure_response = ApplicationService::Response.new(false, nil, "error")

      expect(success_response.failure?).to eq(false)
      expect(failure_response.failure?).to eq(true)
    end

    it 'has payload accessor' do
      response = ApplicationService::Response.new(true, "payload")
      expect(response.payload).to eq("payload")
    end

    it 'has error accessor' do
      error = StandardError.new
      response = ApplicationService::Response.new(false, nil, error)
      expect(response.error).to eq(error)
    end
  end
end
