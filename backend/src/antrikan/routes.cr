module Antrikan
  ROUTES = Marten::Routing::Map.draw do
    space_routes = Marten::Routing::Map.draw(:space) do
      path "/create", SpaceCreateHandler, name: "create"
      path "/index", SpaceIndexHandler, name: "index"
      path "/<space_hashed_id:str>", SpaceShowHandler, name: "show"
      path "/<space_hashed_id:str>/update", SpaceUpdateHandler, name: "update"
      path "/<space_hashed_id:str>/delete", SpaceDeleteHandler, name: "delete"
      path "/<space_hashed_id:str>/qr", SpaceQrHandler, name: "qr"

      code_routes = Marten::Routing::Map.draw(:code) do
        path "/<space_code:str>", SpaceShowHandler, name: "show"
        path "/<space_code:str>/join", SpaceJoinHandler, name: "join"
      end
      path "/code", code_routes

      operating_hour_routes = Marten::Routing::Map.draw(:operating_hour) do
        path "/create", OperatingHourCreateHandler, name: "create"
        path "/index", OperatingHourIndexHandler, name: "index"
        path "/<operating_hour_hashed_id:str>/update", OperatingHourUpdateHandler, name: "update"
        path "/<operating_hour_hashed_id:str>/delete", OperatingHourDeleteHandler, name: "delete"
      end
      path "/<space_hashed_id:str>/operating_hours", operating_hour_routes

      channel_routes = Marten::Routing::Map.draw(:channel) do
        path "/create", ChannelCreateHandler, name: "create"
        path "/index", ChannelIndexHandler, name: "index"
      end
      path "/<space_hashed_id:str>/channels", channel_routes

      queuer_space_routes = Marten::Routing::Map.draw(:queuer) do
        path "/create", QueuerCreateHandler, name: "create"
        path "/index", QueuerIndexHandler, name: "index"
        path "/update", QueuerUpdateHandler, name: "update"
      end
      path "/<space_hashed_id:str>/queuer", queuer_space_routes

      space_review_routes = Marten::Routing::Map.draw(:space_review) do
        path "/create", SpaceReviewCreateHandler, name: "create"
        path "/index", SpaceReviewIndexHandler, name: "index"
      end
      path "/<space_hashed_id:str>/reviews", space_review_routes

      voucher_routes = Marten::Routing::Map.draw(:voucher) do
        path "/create", VoucherCreateHandler, name: "create"
        path "/index", VoucherIndexHandler, name: "index"
      end
      path "/<space_hashed_id:str>/voucher", voucher_routes

      path "/<space_hashed_id:str>/refund/list", RefundSpaceListHandler, name: "refund_list"

      queue_space_routes = Marten::Routing::Map.draw(:queue) do
        path "/create", QueueCreateHandler, name: "create"
        path "/index", QueueIndexHandler, name: "index"
      end
      path "/<space_hashed_id:str>/queue", queue_space_routes
    end

    channel_routes = Marten::Routing::Map.draw(:channel) do
      path "/<channel_hashed_id:str>", ChannelShowHandler, name: "show"
      path "/<channel_hashed_id:str>/update", ChannelUpdateHandler, name: "update"
      path "/<channel_hashed_id:str>/delete", ChannelDeleteHandler, name: "delete"
      path "/<channel_hashed_id:str>/undelete", ChannelUndeleteHandler, name: "undelete"

      item_routes = Marten::Routing::Map.draw(:item) do
        path "/create", ItemCreateHandler, name: "create"
        path "/index", ItemIndexHandler, name: "index"
      end
      path "/<channel_hashed_id:str>/items", item_routes

      operating_hour_routes = Marten::Routing::Map.draw(:operating_hour) do
        path "/create", OperatingHourCreateHandler, name: "create"
        path "/index", OperatingHourIndexHandler, name: "index"
        path "/<operating_hour_hashed_id:str>/update", OperatingHourUpdateHandler, name: "update"
        path "/<operating_hour_hashed_id:str>/delete", OperatingHourDeleteHandler, name: "delete"
      end
      path "/<channel_hashed_id:str>/operating_hours", operating_hour_routes
    end

    queuer_routes = Marten::Routing::Map.draw(:queuer) do
      path "/<queuer_hashed_id:str>", QueuerShowHandler, name: "show"
      path "/<queuer_hashed_id:str>/delete", QueuerDeleteHandler, name: "delete"
      path "/<queuer_hashed_id:str>/undelete", QueuerUndeleteHandler, name: "undelete"
    end

    queue_routes = Marten::Routing::Map.draw(:queue) do
      path "/<queue_slug:str>", QueueShowHandler, name: "show"
      path "/<queue_slug:str>/update", QueueUpdateHandler, name: "update"
      path "/<queue_slug:str>/items/index", QueuedItemIndexHandler, name: "items_index"

      item_routes = Marten::Routing::Map.draw(:item) do
        path "/create", QueuedItemCreateHandler, name: "create"
        path "/rerank", QueuedItemRerankHandler, name: "rerank"
      end
      path "/<queue_slug:str>/item", item_routes

      payment_routes = Marten::Routing::Map.draw(:payment) do
        path "/create", PaymentCreateHandler, name: "create"
        path "/list", PaymentListHandler, name: "list"
      end
      path "/<queue_slug:str>/payment", payment_routes
    end

    item_routes = Marten::Routing::Map.draw(:item) do
      path "/<slug:str>", ItemShowHandler, name: "show"
      path "/<slug:str>/update", ItemUpdateHandler, name: "update"
      path "/<slug:str>/delete", ItemDeleteHandler, name: "delete"
      path "/<slug:str>/undelete", ItemUndeleteHandler, name: "undelete"

      operating_hour_routes = Marten::Routing::Map.draw(:operating_hour) do
        path "/create", OperatingHourCreateHandler, name: "create"
        path "/index", OperatingHourIndexHandler, name: "index"
        path "/<operating_hour_hashed_id:str>/update", OperatingHourUpdateHandler, name: "update"
        path "/<operating_hour_hashed_id:str>/delete", OperatingHourDeleteHandler, name: "delete"
      end
      path "/<item_slug:str>/operating_hours", operating_hour_routes
    end

    space_review_routes = Marten::Routing::Map.draw(:space_review) do
      path "/<space_review_hashed_id:str>", SpaceReviewShowHandler, name: "show"
      path "/<space_review_hashed_id:str>/update", SpaceReviewUpdateHandler, name: "update"
      path "/<space_review_hashed_id:str>/delete", SpaceReviewDeleteHandler, name: "delete"
    end

    voucher_routes = Marten::Routing::Map.draw(:voucher) do
      path "/redeemable", VoucherRedeemabilityHandler, name: "redeemable"
      path "/<voucher_hashed_id:str>", VoucherShowHandler, name: "show"
      path "/<voucher_hashed_id:str>/update", VoucherUpdateHandler, name: "update"
      path "/<voucher_hashed_id:str>/delete", VoucherDeleteHandler, name: "delete"
      path "/<voucher_hashed_id:str>/undelete", VoucherUndeleteHandler, name: "undelete"
    end

    payment_routes = Marten::Routing::Map.draw(:payment) do
      refund_routes = Marten::Routing::Map.draw(:refund) do
        path "/create", RefundCreateHandler, name: "create"
        path "/list", RefundListHandler, name: "list"
      end
      path "/<payment_hashed_id:str>/refund", refund_routes
    end

    refund_routes = Marten::Routing::Map.draw(:refund) do
      path "/<refund_slug:str>", RefundShowHandler, name: "show"
      path "/<refund_slug:str>/accept", RefundAcceptHandler, name: "accept"
      path "/<refund_slug:str>/reject", RefundRejectHandler, name: "reject"
    end

    queued_item_routes = Marten::Routing::Map.draw(:queued_item) do
      path "/update", QueuedItemUpdateHandler, name: "update"
      path "/<queued_item_id:str>/history", QueuedItemHistoryHandler, name: "history"
    end

    path "/api/space", space_routes
    path "/api/channel", channel_routes
    path "/api/queuer", queuer_routes
    path "/api/queue", queue_routes
    path "/api/item", item_routes
    path "/api/space_review", space_review_routes
    path "/api/voucher", voucher_routes
    path "/api/payment", payment_routes
    path "/api/refund", refund_routes
    path "/api/queued_item", queued_item_routes
  end
end
