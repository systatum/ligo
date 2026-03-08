PNG_1X1 = Base64.decode_string("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==")

def build_http_uploaded_file(
  filename : String = "thumbnail.png",
  content : String = PNG_1X1,
) : Marten::HTTP::UploadedFile
  part = HTTP::FormData::Part.new(
    HTTP::Headers{
      "Content-Disposition" => %(form-data; name="profile_picture"; filename="#{filename}"),
    },
    IO::Memory.new(content)
  )

  Marten::HTTP::UploadedFile.new(part)
end

def create_uploaded_file_metadata(
  id : UUID? = UUID.random,
  original_name : String = "thumbnail.png",
  content_type : String = "image/png",
  byte_size : Int64 = PNG_1X1.bytesize.to_i64,
) : UploadedFile
  uploaded_file = UploadedFile.new
  uploaded_file.id = id
  uploaded_file.original_name = original_name
  uploaded_file.content_type = content_type
  uploaded_file.byte_size = byte_size
  uploaded_file.save!

  uploaded_file
end
