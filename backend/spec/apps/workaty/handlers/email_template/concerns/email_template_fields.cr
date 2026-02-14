module EmailTemplateFields
  macro included
    # String fields
    let(title_field) do
      FieldDefinition.new(
        name: "title",
        resource_type: FieldResourceType::EMAIL_TEMPLATE,
        data_type: FieldDataType::DTYPE_STRING,
        is_system_field: true,
        localized_name: LocalizedName.new(english: "Title")
      ).tap(&.save!)
    end

    let(content_field) do
      FieldDefinition.new(
        name: "content",
        resource_type: FieldResourceType::EMAIL_TEMPLATE,
        data_type: FieldDataType::DTYPE_TEXT_RICH,
        is_system_field: true,
        localized_name: LocalizedName.new(english: "Content")
      ).tap(&.save!)
    end

    let(first_name_field) do
      FieldDefinition.new(
        name: "first_name",
        resource_type: FieldResourceType::EMAIL_TEMPLATE,
        data_type: FieldDataType::DTYPE_STRING,
        is_system_field: false,
        localized_name: LocalizedName.new(english: "First Name")
      ).tap(&.save!)
    end

    let(birth_place_field) do
      FieldDefinition.new(
        name: "birth_place",
        resource_type: FieldResourceType::EMAIL_TEMPLATE,
        data_type: FieldDataType::DTYPE_STRING,
        is_system_field: false,
        localized_name: LocalizedName.new(english: "Birth Place")
      ).tap(&.save!)
    end

    let(customer_name_field) do
      FieldDefinition.new(
        name: "customer_name",
        resource_type: FieldResourceType::EMAIL_TEMPLATE,
        data_type: FieldDataType::DTYPE_STRING,
        is_system_field: false,
        localized_name: LocalizedName.new(english: "Customer Name")
      ).tap(&.save!)
    end

    let(city_field) do
      FieldDefinition.new(
        name: "city",
        resource_type: FieldResourceType::EMAIL_TEMPLATE,
        data_type: FieldDataType::DTYPE_STRING,
        is_system_field: false,
        localized_name: LocalizedName.new(english: "City")
      ).tap(&.save!)
    end

    let(category_field) do
      FieldDefinition.new(
        name: "category",
        resource_type: FieldResourceType::EMAIL_TEMPLATE,
        data_type: FieldDataType::DTYPE_STRING,
        is_system_field: false,
        localized_name: LocalizedName.new(english: "Category")
      ).tap(&.save!)
    end

    # Numeric fields
    let(age_field) do
      FieldDefinition.new(
        name: "age",
        resource_type: FieldResourceType::EMAIL_TEMPLATE,
        data_type: FieldDataType::DTYPE_INT,
        is_system_field: false,
        localized_name: LocalizedName.new(english: "Age")
      ).tap(&.save!)
    end

    let(rating_field) do
      FieldDefinition.new(
        name: "rating",
        resource_type: FieldResourceType::EMAIL_TEMPLATE,
        data_type: FieldDataType::DTYPE_FLOAT,
        is_system_field: false,
        localized_name: LocalizedName.new(english: "Rating")
      ).tap(&.save!)
    end

    let(score_field) do
      FieldDefinition.new(
        name: "score",
        resource_type: FieldResourceType::EMAIL_TEMPLATE,
        data_type: FieldDataType::DTYPE_FLOAT,
        is_system_field: false,
        localized_name: LocalizedName.new(english: "Score")
      ).tap(&.save!)
    end

    # Boolean fields
    let(active_field) do
      FieldDefinition.new(
        name: "is_active",
        resource_type: FieldResourceType::EMAIL_TEMPLATE,
        data_type: FieldDataType::DTYPE_BOOLEAN,
        is_system_field: false,
        localized_name: LocalizedName.new(english: "Is Active")
      ).tap(&.save!)
    end

    let(is_reviewed_field) do
      FieldDefinition.new(
        name: "is_reviewed",
        resource_type: FieldResourceType::EMAIL_TEMPLATE,
        data_type: FieldDataType::DTYPE_BOOLEAN,
        is_system_field: false,
        localized_name: LocalizedName.new(english: "Is Reviewed")
      ).tap(&.save!)
    end

    let(verified_field) do
      FieldDefinition.new(
        name: "verified",
        resource_type: FieldResourceType::EMAIL_TEMPLATE,
        data_type: FieldDataType::DTYPE_BOOLEAN,
        is_system_field: false,
        localized_name: LocalizedName.new(english: "Verified")
      ).tap(&.save!)
    end
  end
end
