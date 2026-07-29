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

    private def authorized_for_item?
      item.channel!.space!.owned_by?(current_user!)
    end

    private def authorized_for_item_including_deleted?
      item_even_if_deleted.channel!.space!.owned_by?(current_user!)
    end

    private def schema
      @schema ||= ItemSchema.new(JsonArrayMapper.map(request.data, "carousel_images"))
    end
  end
end
