class MarkdownRenderer
  @template : Marten::Template::Template
  @@cache : Hash(String, MarkdownRenderer) = Hash(String, MarkdownRenderer).new

  def initialize(@template_path : String)
    @template = Marten.templates.get_template(@template_path)
  end

  def render(vars) : String
    ctx = Marten::Template::Context.new
    vars.each { |k, v| ctx[k] = v } if vars
    @template.render(ctx)
  end

  def self.for(template_path : String) : MarkdownRenderer
    @@cache[template_path] ||= new(template_path)
  end
end
