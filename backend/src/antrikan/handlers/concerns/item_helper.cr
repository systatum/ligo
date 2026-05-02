module Antrikan
  module ItemHelper
    @item : Item?
    @schema : ItemSchema?

    private def item
      @item ||= Item
        .filter_by_slug(params["slug"].to_s)
        .get!
    end

    private def item_even_if_deleted
      @item ||= Item
        .filter_by_slug(params["slug"].to_s, unscoped: true)
        .get!
    end

    private def schema
      @schema ||= ItemSchema.new(request.data)
    end
  end
end
