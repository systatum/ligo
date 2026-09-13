require "../spec_helper"

def signed_payload(body : String, secret : String, timestamp : String) : String
  OpenSSL::HMAC.hexdigest(:sha256, secret, "#{body}#{timestamp}")
end

describe Ligo::IamWebhookHandler do
  it "returns 204 with a valid signature and creates a user" do
    ts = Time.utc.to_unix.to_s
    secret = AppSettings.instance.ligo_webhook_secret
    body = %({"user_id":"iam-user-abc","email":"jane@example.com","given_name":"Jane"})
    signature = signed_payload(body, secret, ts)

    response = Marten::Spec.client.post(
      Marten.routes.reverse("iam_webhook"),
      data: body,
      content_type: "application/json",
      headers: {
        "X-Systatum-Timestamp" => ts,
        "X-Systatum-Signature" => signature,
      }
    )

    response.status.should eq 204

    user = Ligo::User.filter(iam_identifier_primary: "iam-user-abc").first?
    user.should_not be_nil
    user.not_nil!.email.should eq "jane@example.com"
  end

  it "returns 403 when signature is invalid" do
    body = %({"user_id":"iam-user-xyz","email":"bob@example.com"})

    response = Marten::Spec.client.post(
      Marten.routes.reverse("iam_webhook"),
      data: body,
      content_type: "application/json",
      headers: {
        "X-Systatum-Timestamp" => Time.utc.to_unix.to_s,
        "X-Systatum-Signature" => "invalid-signature",
      }
    )

    response.status.should eq 403
  end

  it "returns 403 when webhook headers are missing" do
    body = %({"user_id":"iam-user-xyz"})

    response = Marten::Spec.client.post(
      Marten.routes.reverse("iam_webhook"),
      data: body,
      content_type: "application/json"
    )

    response.status.should eq 403
  end

  it "returns 400 when payload body is empty" do
    response = Marten::Spec.client.post(
      Marten.routes.reverse("iam_webhook"),
      data: "",
      content_type: "application/json"
    )

    response.status.should eq 400
  end

  it "returns 400 when user_id is missing from payload" do
    ts = Time.utc.to_unix.to_s
    secret = AppSettings.instance.ligo_webhook_secret
    body = %({"email":"noid@example.com"})
    signature = signed_payload(body, secret, ts)

    response = Marten::Spec.client.post(
      Marten.routes.reverse("iam_webhook"),
      data: body,
      content_type: "application/json",
      headers: {
        "X-Systatum-Timestamp" => ts,
        "X-Systatum-Signature" => signature,
      }
    )

    response.status.should eq 400
  end
end
