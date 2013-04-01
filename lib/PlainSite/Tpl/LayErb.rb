#coding:utf-8
module PlainSite;end
module PlainSite::Tpl
  require 'erb'
  require 'PlainSite/Data/FrontMatterFile'
  require 'PlainSite/Utils'
  require 'PlainSite/Tpl/ExtMethods'

  class LayoutNameException<Exception;end

  # Layout enhanced ERB.Template file is also YAMLFrontMatterFile
  # Example Template Files:
  #   body.html :
  #     ---
  #     layout: layout.html
  #     ---
  #     Store layout content :<% content_for :name %>CONTENT<%end%>
  #
  #   layout.html :
  #     Retrieve content: <%=yield :name%>
  class LayErb
    # Huh? For short name!
    ObjectProxy=PlainSite::Utils::ObjectProxy # module include has many pitfalls
    def initialize(path)
      @path=path
      @template_file=PlainSite::Data::FrontMatterFile.new path
      @layout=@template_file.headers['layout']
    end
    # Render template with context data
    # context - The Object|Hash data
    # yield_contents - The Hash for layout yield retrieves
    def render(context,yield_contents={})
      context=ObjectProxy.new context unless ObjectProxy===context
      contents_store={}
      context.define_singleton_method(:content_for) do |name,&block|
        contents_store[name.to_sym]=echo_block &block
        nil
      end unless context.respond_to? :content_for

      tpl_path=@path
      context.define_singleton_method(:include) do |file|
        file=File.join File.dirname(tpl_path),file
        new_context=context.dup
        LayErb.new(file).render new_context
      end unless context.respond_to? :include

      begin
        result=LayErb.render_s(@template_file.content,context,yield_contents)
      rescue Exception=>e
        $stderr.puts "\nError in template:#{@path}\n"
        raise e
      end
      if @layout
        layout_path=File.join (File.dirname @path), @layout
        return  LayErb.new(layout_path).render context,contents_store
      end
      result
    end

    # Render content with context data
    # content - The String template content
    # context - The Object|Hash data
    # yield_contents - The Hash for layout yield retrieve
    def self.render_s(content,context,yield_contents={})
      context=ObjectProxy.new context unless ObjectProxy===context
      context.singleton_class.class_eval { include ExtMethods }
      erb=ERB.new content,nil,nil,'@_erbout_buf'
      result=erb.result(context.get_binding { |k| yield_contents[k.to_sym] })
      result.strip
    end
  end

end
