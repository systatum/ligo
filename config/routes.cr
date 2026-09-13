Marten.routes.draw do
  path "/uploaded_file/<id:uuid>", UploadedFileShowHandler, name: "uploaded_file_show"
  path "/job/<id:str>", JobStatusHandler, name: "job_status"
end
