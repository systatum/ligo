class ProductStateHandler < RequestHandler
  http_method_names :get, :patch, :post, :delete

  @product : Product?
  @schema : ProductSchema?

  def get
    json ProductSerializer.serialize(product), status: 200
  end

  def post
    patch
  end

  def patch
    if schema.valid?
      product.update!(schema.validated_data)
      json ProductSerializer.serialize(product), status: 200
    else
      render_invalid_payload
    end
  rescue e
    handle_error(e)
  end

  def delete
    product.soft_delete!
    json ProductSerializer.serialize(product), status: 200
  rescue e
    handle_error(e)
  end

  private def product
    @product ||= Product.get!(id: params["pk"])
  end

  private def schema
    @schema ||= ProductSchema.new(request.data)
  end
end
