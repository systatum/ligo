class OrganizationCreateHandler < Marten::Handler
  class Schema < Marten::Schema
    field :name, :string, max_size: 255
  end

  @schema : Schema?

  def render_error(status_code, message)
    response_payload = Jbuilder.new do |json|
      json.messages [message]
    end.to_json

    json response_payload, status: status_code
  end

  def post
    if schema.valid?
      organization = Organization.new(schema.validated_data)
      organization.save!
      json OrganizationSerializer.serialize(organization), status: 200
    else
      render_error 400, "Invalid organization payload"
    end
  end

  private def schema
    @schema ||= Schema.new(request.data)
  end
end
