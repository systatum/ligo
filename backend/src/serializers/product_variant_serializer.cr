class ProductVariantSerializer < ModelSerializer
  protected def fields
    record = @record.as(ProductVariant)

    {
      id: record.hashed_id,
      product_id: record.product_id,
      name: record.name,
      description: record.description,
    }
  end
end
