#coding:utf-8

module PlainSite;end
module PlainSite::Tpl
  require 'erb'
  module ExtMethods
    require 'uri'
    require 'json'
    require 'securerandom'
    include ERB::Util
    def echo_block(&block)
      old=@_erbout_buf
      @_erbout_buf=""
      block.call
      block_content=@_erbout_buf.strip
      @_erbout_buf=old
      block_content
    end

    def raw(&block)
      code=echo_block &block
      @_erbout_buf << (html_escape code)
    end

    def iframe(attrs={},&block)
      attrs[:width]=attrs[:width] || "100%"
      attrs[:height]=attrs[:height] || "100%"
      attrs= attrs.to_a.map do |a|
        k,v=a
        "#{k}=\"#{v}\""
      end.join " "
      html=echo_block &block
      html="
      <!DOCTYPE html>
      <html>
      <head>
        <title>IFrame</title>
      </head>
      <body>#{html}</body>
      </html>
      "

      html=html.to_json
      id='ID_'+(SecureRandom.uuid.gsub '-','')
      @_erbout_buf << "
      <iframe #{attrs} src='about:blank' id='#{id}'></iframe>
      <script>
        setTimeout(function () {
          document.getElementById('#{id}').contentWindow.document.write(#{html})
        },0);
      </script>
      "
    end
  end
end
