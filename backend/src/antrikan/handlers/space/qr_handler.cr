require "qr-code"
require "qr-code/export/png"

class Antrikan::SpaceQrHandler < RequestHandler
  include Antrikan::SpaceHelper

  protect_from_forgery false
  http_method_names :get

  def get
    qr_code = QRCode.new(space.code!, size: 4, level: :h)
    png_bytes = qr_code.as_png(size: 256)
    base64_png = Base64.strict_encode(png_bytes)

    response_payload = Jbuilder.new do |json|
      json.code space.code
      json.qr_base64 base64_png
      json.content_type "image/png"
    end.to_json

    json response_payload, status: 200
  end
end
