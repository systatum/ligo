class Antrikan::SpaceJoinHandler < RequestHandler
  include Antrikan::SpaceHelper

  protect_from_forgery false
  http_method_names :post

  def post
    current_user!

    result = Space::MemberRegisterService.new(space, request.data).run

    return render_invalid_payload(result.errors) if result.failure?

    join_result = result.data.not_nil!
    status_code = status_code_of join_result

    added_users = join_result.added.map do |user|
      Auth::UserSerializer.soft_serialize(user)
    end

    failed_users = join_result.failed.map do |user|
      Auth::UserSerializer.soft_serialize(user)
    end

    invalid_ids = join_result.invalid_ids.map { |id| {"id" => id} }

    json({
      added:  added_users,
      failed: failed_users + invalid_ids,
    }, status: status_code)
  end

  private def status_code_of(result : SpaceJoinResult) : Int
    if result.empty_payload?
      200
    elsif result.all_failed?
      500
    else
      201
    end
  end
end
