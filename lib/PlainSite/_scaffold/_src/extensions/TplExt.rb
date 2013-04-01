#coding:utf-8

module PlainSite;end
module PlainSite::Tpl
  module ExtMethods
    def your_custom_template_method(&block)
      """
      <% your_custom_template_method do %>
        Echo!
      <% end %>
      """
      code=echo_block &block
      @_erbout_buf << code
    end

    def your_mystery_tpl_method
      """
        <%=your_mystery_tpl_method%>
      """
      "Mystery!"
    end
  end
end
