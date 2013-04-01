#coding:utf-8
module PlainSite;end
module PlainSite::Data
  require 'pygments'
  require 'kramdown'
  require 'date'
  require 'securerandom'
  require 'PlainSite/Data/FrontMatterFile'
  require 'PlainSite/Tpl/LayErb'
  require 'PlainSite/Data/Category'

  class Post
    attr_reader(
      :slug, # The String slug of post,default is it's filename without date and dot-extname
      :path, # The String post file path
      :relpath, # The String path relative to site.data_path
      :data_id, # The String data id,format:'category/sub-category/slug'
      :category_path, # The String category path
      :filename, # The String filename
      :site,
      :is_index # The Bool to indicate if this is an index post.
    )

    attr_accessor( #These properties are inited by others
      :prev_post, # The Post previous,set by PostList
      :next_post, # The Post next,set by PostList
    )

    DATE_NAME_RE=/^(\d{4})-(\d{1,2})-(\d{1,2})-(.+)$/
    HIGHLIGHT_RE=/<highlight(\s+[^>]+)?\s*>(.+?)<\/highlight>/m
    MARKDOWN_CODE_RE=/```(.+?)```/m


    # Init a post
    # path - The String file abs path,at present,only support '.html' and '.md' extname.
    # site - The Site this post belongs to
    def initialize(path,site)
      if File.directory? path # create as category index post
        path=(@@extnames.map {|x| File.join path+'/index'+x}).detect {|f| File.exists? f}
        @is_index=true
      end
      @site=site
      @path=path
      @relpath=@path[(site.data_path.length+1)..-1]

      @filename=File.basename @path
      @extname=File.extname @filename
      if DATE_NAME_RE =~ @filename
        @date=Date.new $1.to_i,$2.to_i,$3.to_i
        @slug=File.basename $4,@extname
      end
      @slug=File.basename @filename,@extname unless @slug

      @category_path=File.dirname(@relpath)

      if @category_path=='/' or @category_path=='.'
        @category_path=''
        @data_id=@slug
      else
        @data_id=File.join @category_path,@slug
      end

    end
    # The Date of post
    def date
      return @date if @date
      @date=get_date 'date'
    end

    def get_date(k)
      date=post_file.headers[k]

      date=if String===date
              begin Date.parse(date) rescue Date.today end
            elsif Date===date
              date
            else
              Date.today
            end
    end
    private :get_date

    def updated_date
      return @updated_date if @updated_date
      @updated_date=get_date 'updated_date'
    end

    # The Category this post belongs to
    def category
      return @category if @category
      @category=Category.new File.join(@site.data_path,@category_path),@site
    end

    # The String content type of post,default is it's extname without dot
    def content_type
      return @content_type if @content_type
      @content_type=post_file.headers['content_type']
      @content_type=@extname[1..-1] if @content_type.nil?
      @content_type
    end

    # The Boolean value indicates if this post is a draft,default is false,alias is `draft?`
    # def draft
    #   return @draft unless @draft.nil?
    #   @draft=!!post_file.headers['draft']
    # end
    # alias :draft? :draft

    # def deleted
    #   return @deleted unless @deleted.nil?
    #   @deleted=!!post_file.headers['deleted']
    # end
    # alias :deleted? :deleted

    # Private
    def post_file
      return @post_file if @post_file
      @post_file=FrontMatterFile.new @path
    end
    private :post_file

    # Post file raw content
    def raw_content
      post_file.content
    end

    # Rendered html content
    # It must render highlight code first.
    # Highlight syntax:
    #   Html tag style:
    #     <highlight>puts 'Hello'</highlight>
    #     With line numbers and language
    #     <highlight ruby linenos>puts 'Hello'</highlight>
    #     Set line number start from 10
    #     <highlight ruby linenos=10>puts 'Hello'</highlight>
    #     Highlight lines
    #     <highlight ruby linenos hl_lines=1>puts 'Hello'</highlight>
    #
    #     Highlight html tag options:
    #       linenos - If provide,output will contains line number
    #       linenos=Int - Line number start from,default is 1
    #   If no new line in code,the output will be inline nowrap style and no linenos.
    #
    #   You can also use markdown style code block,e.g. ```puts 'Code'```.
    #   But code this style doesn't rendered by Pygments.
    #   You need to load a browser side renderer,viz. SyntaxHighlighter.
    #
    # Then render erb template,context is post itself,you can access self and self.site methods
    #
    # Return the String html content
    def content
      # quick fix,when build local, current path will change
      p=@path + "::"+ @site._cur_page_dir

      post_content=raw_content.dup
      # stash highlight code
      codeMap={}
      post_content.gsub! HIGHLIGHT_RE  do
        placeholder='-HIGHLIGHT '+SecureRandom.uuid+' ENDHIGHLIGHT-'
        attrs=$1
        attrs=attrs.split " "
        lexer=attrs.shift || ""
        attrs=Hash[attrs.map {|v| v.split "="}]
        attrs["hl_lines"]=(attrs["hl_lines"] || "").split ","
        code=$2
        codeMap[placeholder]={
          lexer: lexer,
          linenos: (attrs.key? "linenos") ? 'table' : false ,
          linenostart: attrs["linenos"] || 1,
          hl_lines: attrs["hl_lines"],
          code: code.strip,
          nowrap: code["\n"].nil?
        }
        placeholder
      end


      # Then render erb template if needed
      if post_content['<%'] && !post_file.headers['disable_erb']
        post_content=PlainSite::Tpl::LayErb.render_s post_content,self
      end

      post_content=self.class.content_to_html post_content,content_type

      #put back code
      codeMap.each do |k,v|
        code=Pygments.highlight v[:code],lexer: v[:lexer],formatter: 'html',options:{
            linenos: v[:linenos],
            linenostart: v[:linenostart],
            nowrap: v[:nowrap],
            hl_lines: v[:hl_lines],
            startinline: v[:lexer] == 'php'
        }
        code="<code class=\"highlight\">#{code}</code>" if v[:nowrap]
        post_content[k]=code # String#sub method has a hole of back reference
      end

      return post_content
    end

    # The String url of this post in site
    def url
      @site.url_for @data_id
    end

    # You can use method call to access post file front-matter data
    def respond_to?(name)
      return true if post_file.headers.key? name.to_s
      super
    end

    def method_missing(name,*args,&block)
      if args.length==0 && block.nil? &&  post_file.headers.key?(name.to_s)
        return post_file.headers[name.to_s]
      end
      super
    end

    def self.content_to_html(content,content_type)
      if content_type=='md'
        content=Kramdown::Document.new(content,input:'GFM').to_html
      end
      content
    end

    @@extnames=['md','html']

    def self.extnames
      @@extnames
    end

    def self.extname_ok?(f)
      @@extnames.include?  File.extname(f)[1..-1]
    end

  end # class Post
end # module PlainSite::Data
