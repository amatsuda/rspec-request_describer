require "rspec/request_describer/version"

module RSpec
  module RequestDescriber
    RESERVED_HEADER_NAMES = %w(
      Content-Type
      Host
      HTTPS
    )

    SUPPORTED_METHODS = %w(
      DELETE
      GET
      PATCH
      POST
      PUT
    )

    class << self
      def included(base)
        base.instance_eval do
          subject do
            send_request
          end

          let(:send_request) do
            process(
              http_method,
              path,
              headers: env,
              params: request_body,
            )
          end

          let(:request_body) do
            if headers.any? { |key, value| key.downcase == "content-type" && value == "application/json" }
              params.to_json
            else
              params
            end
          end

          let(:headers) do
            {}
          end

          let(:params) do
            {}
          end

          let(:env) do
            headers.inject({}) do |result, (key, value)|
              key = "HTTP_" + key unless RESERVED_HEADER_NAMES.include?(key)
              key = key.gsub("-", "_").upcase
              result.merge(key => value)
            end
          end

          let(:endpoint_segments) do
            current_example = ::RSpec.respond_to?(:current_example) ? ::RSpec.current_example : example
            current_example.full_description.match(/(#{::Regexp.union(SUPPORTED_METHODS)}) (\S+)/).to_a
          end

          # @return [Symbol] e.g. `:get`
          let(:http_method) do
            endpoint_segments[1].downcase.to_sym
          end

          let(:path) do
            endpoint_segments[2].gsub(/:(\w+[!?=]?)/) { send($1) }
          end
        end
      end
    end
  end
end
