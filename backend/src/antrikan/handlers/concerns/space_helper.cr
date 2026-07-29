module Antrikan::SpaceHelper
  @space : Space?
  @schema : SpaceSchema?

  private def space
    @space ||= filter_by_param.get!
  end

  private def filter_by_param
    if params.has_key?("space_code")
      Space.filter_by_code(params["space_code"].to_s)
    else
      Space.filter_by_hashed_id(params["space_hashed_id"].to_s)
    end
  end

  private def owner_of_space?
    space.owned_by?(current_user!)
  end

  private def schema
    @schema ||= SpaceSchema.new(request.data)
  end
end
