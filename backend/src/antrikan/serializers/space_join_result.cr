module Antrikan
  struct SpaceJoinResult
    getter added : Array(Auth::User)
    getter failed : Array(Auth::User)
    getter invalid_ids : Array(String)

    def initialize(
      @added = [] of Auth::User,
      @failed = [] of Auth::User,
      @invalid_ids = [] of String,
    )
    end

    def any_added?
      !@added.empty?
    end

    def any_failed?
      !@failed.empty? || !@invalid_ids.empty?
    end

    def all_failed?
      @added.empty? && any_failed?
    end

    def empty_payload?
      @added.empty? && @failed.empty? && @invalid_ids.empty?
    end
  end
end
