class ProductCreateHandler < RequestHandler
  protect_from_forgery false
  http_method_names :post

  @schema : ProductSchema?

  def post
    if schema.valid?
      product = Product.new(schema.validated_data)
      product.organization = current_user!.organization
      product.save!
      json ProductSerializer.serialize(product), status: 200
    else
      render_invalid_payload(schema)
    end
  end

  private def schema
    @schema ||= ProductSchema.new(request.data)
  end
end
