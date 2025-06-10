class ProductStateHandler < RequestHandler
  protect_from_forgery false
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
    Auth::Role.must_at_least_bizdev!(current_user)

    if schema.valid?
      product.update!(schema.validated_data)
      json ProductSerializer.serialize(product), status: 200
    else
      render_invalid_payload(schema)
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
    @product ||= Product
      .filter_by_hashed_id(params["id"].to_s)
      .get!(organization_id: current_user!.organization_id)
  end

  private def schema
    @schema ||= ProductSchema.new(request.data)
  end
end
