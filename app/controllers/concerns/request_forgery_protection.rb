module RequestForgeryProtection
  extend ActiveSupport::Concern

  included do
    protect_from_forgery using: :header_only, with: :exception
  end

  private
    def verified_via_header_only?
      super || allowed_api_request?
    end

    def allowed_api_request?
      sec_fetch_site_value.in?([ nil, "none" ]) && request.format.json?
    end
end
