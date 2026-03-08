require "../spec_helper"

class FileCommitterServiceWithDeterministicID < FileCommitterService
  FIXED_ID = UUID.new("00000000-0000-0000-0000-000000000111")

  protected def generate_file_id : UUID
    FIXED_ID
  end
end
