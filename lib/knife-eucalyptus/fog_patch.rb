#This monkey patch changes Fog to connect to Eucalyptus using version 2 signed params instead of the newer v4 which doesn't work on our version of Eucalyptus
require 'fog'
module Fog
  module Compute
    class AWS < Fog::Service
      class Real
        def request(params)
          refresh_credentials_if_expired
          idempotent  = params.delete(:idempotent)
          parser      = params.delete(:parser)

          body, headers = Fog::AWS.signed_params(
             params,
             {
               :aws_access_key_id  => @aws_access_key_id,
               :aws_session_token  => @aws_session_token,
               :hmac               => Fog::HMAC.new('sha256', @aws_secret_access_key),
               :host               => @host,
               :path               => @path,
               :port               => @port,
               :version            => '2010-08-31'
            }
          )
          if @instrumentor
            @instrumentor.instrument("#{@instrumentor_name}.request", params) do
              _request(body, headers, idempotent, parser)
            end
          else
            _request(body, headers, idempotent, parser)
          end
        end
      end
    end
  end
end