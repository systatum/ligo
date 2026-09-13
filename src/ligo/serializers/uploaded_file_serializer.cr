class UploadedFileSerializer < ModelSerializer
  protected def fields
    record = @record.as(Ligo::UploadedFile)

    {
      id:            record.id.try(&.to_s),
      original_name: record.original_name,
      content_type:  record.content_type,
      byte_size:     record.byte_size,
      url:           Marten.routes.reverse("uploaded_file_show", id: record.id.to_s),
    }
  end
end
