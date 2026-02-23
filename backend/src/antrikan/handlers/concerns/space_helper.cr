module Antrikan::SpaceHelper
  @space : Space?
  @schema : SpaceSchema?

  private def space
    @space ||= Space
      .filter_by_hashed_id(params["space_hashed_id"].to_s)
      .get!(user_id: current_user!.id)
  end

  private def schema
    @schema ||= SpaceSchema.new(request.data)
  end
end
