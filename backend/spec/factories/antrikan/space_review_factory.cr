require "../user_factory"
require "./space_factory"

def create_space_review(
  space : Antrikan::Space = create_space,
  reviewer : Auth::User? = create_user,
  rating : Float64 = 8.0,
  review : String? = "Great space!",
) : Antrikan::SpaceReview
  space_review = Antrikan::SpaceReview.new
  space_review.space = space
  space_review.reviewer = reviewer
  space_review.rating = rating
  space_review.review = review
  space_review.save!

  space_review
end
