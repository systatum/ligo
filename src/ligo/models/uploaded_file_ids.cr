# JSON-serializable wrapper for an ordered list of `UploadedFile` UUID strings -
# used for any resource that attaches a set of uploaded images/files (e.g.
# a listing's photo carousel, evidence photos on a claim). Not an ORM model
# (no table of its own) and not input/output-shaped like a schema/serializer,
# so it lives alongside other plain structs instead.
class UploadedFileIds
  include JSON::Serializable

  property ids : Array(String)

  def initialize(@ids : Array(String) = [] of String)
  end
end
