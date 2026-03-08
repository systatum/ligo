require "./spec_helper.cr"

describe FileCommitterService do
  describe "#run" do
    context "when creating a new uploaded file" do
      it "persists uploaded file metadata and writes content to storage" do
        file = build_http_uploaded_file

        result = FileCommitterService.new(file).run

        result.success?.should be_true

        uploaded = result.data.not_nil!
        persisted = UploadedFile.get(id: uploaded.id).not_nil!

        persisted.original_name.should eq "thumbnail.png"
        persisted.content_type.should eq "image/png"
        persisted.byte_size.should eq PNG_1X1.bytesize.to_i64
        Marten.media_files_storage.exists?(persisted.id.to_s).should be_true
      end

      it "falls back to generated key when filename is blank" do
        file = build_http_uploaded_file(filename: "")

        result = FileCommitterService.new(file).run

        result.success?.should be_true

        uploaded = result.data.not_nil!
        persisted = UploadedFile.get(id: uploaded.id).not_nil!

        persisted.original_name.should eq persisted.id.to_s
        persisted.content_type.should eq "application/octet-stream"
      end

      it "preserves unicode filename without extension" do
        filename = "プロフィール画像"
        file = build_http_uploaded_file(filename: filename)

        result = FileCommitterService.new(file).run

        result.success?.should be_true

        persisted = UploadedFile.get(id: result.data.not_nil!.id).not_nil!
        persisted.original_name.should eq filename
        persisted.content_type.should eq "application/octet-stream"
      end
    end

    context "when existing uploads already exist" do
      it "creates a new uploaded file and keeps existing one unchanged" do
        existing = create_uploaded_file_metadata(
          original_name: "old_profile_picture.png",
          content_type: "image/png",
          byte_size: 10_i64,
        )

        Marten.media_files_storage.write(existing.id.to_s, IO::Memory.new("old"))

        new_file = build_http_uploaded_file(filename: "new_profile_picture.png")

        result = FileCommitterService.new(new_file).run

        result.success?.should be_true
        uploaded = result.data.not_nil!
        uploaded.id.should_not eq existing.id

        persisted = UploadedFile.get(id: existing.id).not_nil!
        persisted.original_name.should eq "old_profile_picture.png"
        persisted.content_type.should eq "image/png"
        persisted.byte_size.should eq 10_i64

        UploadedFile.count.should eq 2
        Marten.media_files_storage.exists?(existing.id.to_s).should be_true
        Marten.media_files_storage.exists?(uploaded.id.to_s).should be_true

        storage_content = Marten.media_files_storage.open(existing.id.to_s).gets_to_end
        storage_content.should eq "old"
      end
    end

    context "when commit fails" do
      it "returns failure when storage write fails" do
        file = build_http_uploaded_file
        file.io.close

        result = FileCommitterService.new(file).run

        result.failure?.should be_true
        result.errors.should_not be_nil
        result.errors.not_nil!.size.should be > 0
        UploadedFile.count.should eq 0
      end

      it "rolls back committed file when commit fails" do
        key = FileCommitterServiceWithDeterministicID::FIXED_ID.to_s
        too_long_filename = "a" * 256
        file = build_http_uploaded_file(filename: too_long_filename)

        result = FileCommitterServiceWithDeterministicID.new(file).run

        result.failure?.should be_true
        result.errors.should_not be_nil
        result.errors.not_nil!.size.should be > 0
        UploadedFile.count.should eq 0
        Marten.media_files_storage.exists?(key).should be_false
      end
    end
  end
end
