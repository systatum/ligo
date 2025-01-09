class ProductSerializer < ModelSerializer
  protected def fields
    record = @record.as(Product)

    {
      id: record.hashed_id,
      name: record.name,
      short_description: record.short_description,
      note: record.note,
    }
  end
end
