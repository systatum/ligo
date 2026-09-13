Marten.routes.draw do
  path "/uploaded_file/<id:uuid>", UploadedFileShowHandler, name: "uploaded_file_show"
end
