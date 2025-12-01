module Current
  def self.set_performer_id(user_id : Int32 | Int64 | Nil)
    Fiber.current.sys_authenticated_user_id = user_id ? user_id.to_i64 : nil
  end

  def self.performer_id : Int64?
    Fiber.current.sys_authenticated_user_id
  end

  def self.clear
    Fiber.current.sys_authenticated_user_id = nil
  end
end
