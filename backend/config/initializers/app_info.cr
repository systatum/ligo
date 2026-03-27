require "yaml"

module AppInfo
  APP_INFO_FILE_PATH = File.expand_path("../../src/app_info.yml", __DIR__)

  class AppDetail
    include YAML::Serializable

    getter name : String
    getter description : LocalizedName
  end

  @@all : Hash(String, AppDetail)?
  @@workaty : AppDetail?
  @@antrikan : AppDetail?

  def self.all
    @@all ||= Hash(String, AppDetail).from_yaml(File.read(APP_INFO_FILE_PATH))
  end

  def self.find?(app_name : String)
    all[app_name]?
  end

  def self.find(app_name : String)
    all[app_name]
  end

  def self.workaty
    @@workaty ||= find?("workaty")
  end

  def self.antrikan
    @@antrikan ||= find?("antrikan")
  end
end
