require "../spec_helper"

def with_webhook_receiver(response_status : Int32 = 204, &block : Int32 -> T) forall T
  received = Channel(NamedTuple(body: String, headers: HTTP::Headers)).new(1)

  server = HTTP::Server.new do |ctx|
    body = ctx.request.body.try(&.gets_to_end) || ""
    received.send({body: body, headers: ctx.request.headers})
    ctx.response.status_code = response_status
  end

  addr = server.bind_tcp("127.0.0.1", 0)
  port = addr.port

  spawn do
    server.listen
  rescue IO::Error
  end

  Fiber.yield

  block.call(port)

  select
  when req = received.receive
    req
  when timeout(5.seconds)
    raise "Timed out waiting for webhook request on port #{port}"
  end
ensure
  server.try(&.close)
end

describe WebhookDeliveryWorker do
  describe "#perform" do
    it "creates a successful delivery when target responds 204" do
      content_id = UUID.random.to_s
      body = %({"event":"registration"})
      secret = "test-secret"
      ts = Time.utc.to_unix.to_s
      sig = OpenSSL::HMAC.hexdigest(:sha256, secret, "#{body}#{ts}")

      request = with_webhook_receiver(response_status: 204) do |port|
        WebhookDeliveryWorker.new.perform(content_id, "http://127.0.0.1:#{port}/hook", secret, body)
      end

      request[:headers]["X-Systatum-Timestamp"]?.should eq ts
      request[:headers]["X-Systatum-Signature"]?.should eq sig

      delivery = Ligo::WebhookDelivery.filter(content_id: content_id).first!
      delivery.succeeded.should be_true
    end

    it "creates a successful delivery when target responds 200" do
      content_id = UUID.random.to_s
      body = %({"event":"registration"})
      secret = "test-secret"

      with_webhook_receiver(response_status: 200) do |port|
        WebhookDeliveryWorker.new.perform(content_id, "http://127.0.0.1:#{port}/hook", secret, body)
      end

      delivery = Ligo::WebhookDelivery.filter(content_id: content_id).first!
      delivery.succeeded.should be_true
    end

    context "with MUTUAL semantic" do
      it "sets acked_at on the realm_user when delivery succeeds" do
        content_id = UUID.random.to_s
        body = %({"event":"registration"})
        secret = "test-secret"
        realm = create_realm(ack_semantic: AcknowledgeSemantic::MUTUAL)
        user = create_user
        Ligo::RealmUser.create!(
          user: user,
          provider: 0,
          provider_user_id: "fb-uid",
          realm: realm,
          registration_webhook_content_id: content_id
        )

        with_webhook_receiver(response_status: 204) do |port|
          WebhookDeliveryWorker.new.perform(content_id, "http://127.0.0.1:#{port}/hook", secret, body, AcknowledgeSemantic::MUTUAL)
        end

        realm_user = Ligo::RealmUser.filter(registration_webhook_content_id: content_id).first!
        realm_user.acked_at.should_not be_nil
      end

      it "raises when the target responds 500" do
        content_id = UUID.random.to_s
        body = %({"event":"registration"})
        secret = "test-secret"

        expect_raises(Exception, /Webhook delivery failed/) do
          with_webhook_receiver(response_status: 500) do |port|
            WebhookDeliveryWorker.new.perform(content_id, "http://127.0.0.1:#{port}/hook", secret, body, AcknowledgeSemantic::MUTUAL)
          end
        end

        delivery = Ligo::WebhookDelivery.filter(content_id: content_id).first!
        delivery.succeeded.should be_false
      end

      it "raises when the target is unreachable" do
        content_id = UUID.random.to_s
        body = %({"event":"registration"})
        secret = "test-secret"

        expect_raises(Exception) do
          WebhookDeliveryWorker.new.perform(content_id, "http://localhost:18999/nonexistent", secret, body, AcknowledgeSemantic::MUTUAL)
        end

        delivery = Ligo::WebhookDelivery.filter(content_id: content_id).first!
        delivery.succeeded.should be_false
      end
    end

    context "with OPTIONAL semantic" do
      it "does not set acked_at on the realm_user when delivery succeeds" do
        content_id = UUID.random.to_s
        body = %({"event":"registration"})
        secret = "test-secret"
        realm = create_realm(ack_semantic: AcknowledgeSemantic::OPTIONAL)
        user = create_user
        Ligo::RealmUser.create!(
          user: user,
          provider: 0,
          provider_user_id: "fb-uid",
          realm: realm,
          registration_webhook_content_id: content_id
        )

        with_webhook_receiver(response_status: 204) do |port|
          WebhookDeliveryWorker.new.perform(content_id, "http://127.0.0.1:#{port}/hook", secret, body, AcknowledgeSemantic::OPTIONAL)
        end

        realm_user = Ligo::RealmUser.filter(registration_webhook_content_id: content_id).first!
        realm_user.acked_at.should be_nil
      end

      it "does not raise when the target responds 500" do
        content_id = UUID.random.to_s
        body = %({"event":"registration"})
        secret = "test-secret"

        with_webhook_receiver(response_status: 500) do |port|
          WebhookDeliveryWorker.new.perform(content_id, "http://127.0.0.1:#{port}/hook", secret, body, AcknowledgeSemantic::OPTIONAL)
        end

        delivery = Ligo::WebhookDelivery.filter(content_id: content_id).first!
        delivery.succeeded.should be_false
      end
    end

    context "with NONE semantic" do
      it "returns early without delivering" do
        content_id = UUID.random.to_s

        WebhookDeliveryWorker.new.perform(content_id, "http://localhost:18999/nonexistent", "", "", AcknowledgeSemantic::NONE)

        Ligo::WebhookDelivery.filter(content_id: content_id).count.should eq 0
      end
    end
  end
end
