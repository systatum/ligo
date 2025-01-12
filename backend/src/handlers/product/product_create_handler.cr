class ProductCreateHandler < RequestHandler
  @schema : ProductSchema?

  http_method_names :post

  def post
    if schema.valid?
      product = Product.new(schema.validated_data)
      product.organization = Organization.get!(id: product.organization_id)
      product.save!
      json ProductSerializer.serialize(product), status: 200
    else
      render_invalid_payload
    end
  end

  private def schema
    @schema ||= ProductSchema.new(request.data)
  end
end
