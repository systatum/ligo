module Current
  def self.set_performer_id(user_id : Int32 | Int64 | Nil)
    Fiber.current.sys_authenticated_user_id = user_id ? user_id.to_i64 : nil
  end

  def self.set_request_context(ip : String?, path : String?)
    Fiber.current.sys_request_ip = ip
    Fiber.current.sys_request_path = path
  end

  def self.performer_id : Int64?
    Fiber.current.sys_authenticated_user_id
  end

  def self.user : Ligo::User?
    performer_id.try { |id| Ligo::User.get(id: id) }
  end

  def self.ip : String?
    Fiber.current.sys_request_ip
  end

  def self.path : String?
    Fiber.current.sys_request_path
  end

  def self.clear
    Fiber.current.sys_authenticated_user_id = nil
    Fiber.current.sys_request_ip = nil
    Fiber.current.sys_request_path = nil
  end
end
