require "../../spec_helper"

DEFAULT_MULTIPART_BOUNDARY = "B0UnDaRyUnIqU3"

def auth_headers_for(user)
  {authorization: "Bearer #{user.jwt_token}"}
end

def multipart_content_type(boundary = DEFAULT_MULTIPART_BOUNDARY)
  "multipart/form-data; boundary=#{boundary}"
end

def profile_picture_param(uploaded_file)
  {"profile_picture" => uploaded_file.io}
end

def invalid_profile_picture_body(boundary, filename, content)
  [
    "--#{boundary}",
    "Content-Disposition: form-data; name=\"profile_picture\"; filename=\"#{filename}\"",
    "Content-Type: text/plain",
    "",
    content,
    "--#{boundary}--",
    "",
  ].join("\r\n")
end
