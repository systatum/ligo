module Antrikan
  class ChannelCreateHandler < RequestHandler
    include SpaceHelper
    include ChannelHelper

    @schema : ChannelSchema?

    protect_from_forgery false
    http_method_names :post

    def post : Marten::HTTP::Response
      raise Marten::HTTP::Errors::PermissionDenied.new unless current_user!.admin?

      if schema.valid?
        ch = Channel.new
        ch.space = space

        data = schema.validated_data
        ch.name = data["name"].as(String)

        desc = data["description"]?.as?(String)
        ch.description = desc.nil? || desc.empty? ? nil : desc

        ch.logo_file_id = upload_image(schema.logo)

        ch.save!
        json ChannelSerializer.serialize(ch), status: 201
      else
        render_invalid_payload(schema)
      end
    rescue ex : ::Errors::LogoUploadException
      render_invalid_payload(ex.errors)
    end
  end
end
