#coding:utf-8

module PlainSite
  require 'fileutils'
  require 'pathname'
  require 'PlainSite/Data/PostList'
  require 'PlainSite/Data/PostListPage'
  require 'PlainSite/Data/Post'
  require 'PlainSite/Tpl/LayErb'
  require 'PlainSite/Utils'

  class BadUrlPatternException<Exception;end
  class RenderTask
    Post=Data::Post
    PostList=Data::PostList
    PostListPage=Data::PostListPage
    attr_reader :site
    # site - The Site
    def initialize(site)
      @site=site
      @tasks=[]
    end

    # Options:
    # url_pattern - The String with var replacement pattern "{property.property}"
    #       "{property.property}" is the data Hash key path.
    #       Example:
    #       "/article/{date.year}/{name}.html" will render url
    #       "/article/2011/hello-world.html"
    #           with post "posts/2011-09-09-hello-world.md"
    # data - The Array|PostList|Object|String data to render
    #    In String case,it represents the post.data_id or category.data_id.
    #    Example: 'essay/*' same as $site.data['essay/*']
    #    If `data` type is Array or PostList,it will render each item with template,
    #    else only generate one page
    # template - The String template path relative to '_site/templates'
    # build_anyway - The Boolean value to indicate
    #           this route rule will build anyway even if no post updates
    def route(opts)
      url_pattern=opts[:url_pattern]
      items=opts[:data]
      template=opts[:template]
      build_anyway=opts[:build_anyway]

      if String===items
        items=@site.data[items]
        raise Exception,"Data not found:#{opts[:data]}!" if items.nil?
      end
      items=[items] unless Data::PostList===items || Array===items

      tasks= items.map do |item|
        urlpath=RenderTask.sub_url url_pattern,item
        urlpath[0]=''  if urlpath[0]=='/'
        id =if item.respond_to? :data_id
              item.data_id
            else
              item.object_id
            end

        { id: id, urlpath: urlpath, item: item,
          template:File.join(@site.templates_path,template),
          build_anyway:build_anyway }
      end
      @tasks.concat tasks
    end

    # Get the url for object
    # obj - The Post|PageListPage|Category|String
    # Return the String url prefix with site root url(site.url) or relative path if build --local
    def url_for(obj)
      obj[0]='' if String===obj && obj[0]=='/'

      if String===obj && (File.exists? (File.join @site.assets_path,obj))
        # static file path
        urlpath=obj
      else
        urlpath=object2url obj
      end

      if @site.local
        urlpath=urlpath+'/index.html' if urlpath.end_with? '/'
        urlpath='index.html'  if urlpath.empty?
        p1=Pathname.new (File.dirname urlpath)
        basename=File.basename urlpath
        (p1.relative_path_from Pathname.new(@site._cur_page_dir)).to_s+'/'+basename
      else
        #URI.join @site.url,urlpath
        '/' + urlpath
      end
    end

    def object2url(obj)
      id =if String===obj
            obj
          elsif obj.respond_to? :data_id
            obj.data_id
          else
            obj.object_id
          end
      return (id2url_map[id] || id).to_s
    end

    # Return all valid output pages url path
    def all_urlpath
      return @all_urlpath  if @all_urlpath
      @all_urlpath=@tasks.map do |t|
        t[:urlpath]
      end
    end

    # Render  pages
    # partials - The Hash of new or updated and deleted posts and templates.
    #            If nil,it will render all pages.
    # Structure:
    # {
    #   updated_posts:[],
    #   updated_templates:[],
    #   has_deleted_posts:Bool
    # }
    def render(partials=nil)
      if partials.nil?
        return @tasks.each {|t|render_task t}
      end
      build_tasks,other_tasks=@tasks.partition {|t|!!t[:build_anyway]}

      if tpls=partials[:updated_templates]
        a,other_tasks=other_tasks.partition {|t|tpls.include? t[:template] }
        build_tasks.concat a
      end
      if posts=partials[:updated_posts]
        a,other_tasks=other_tasks.partition do |t|
          _detectContainsPosts(t[:item],posts)
        end
        build_tasks.concat a
      end

      if partials[:has_deleted_posts]
        # rebuild all post list pages
        a,other_tasks=other_tasks.partition {|t|PostList===t[:item] || PostListPage===t[:item]}
        build_tasks.concat a
      end
      build_tasks.each do |t|
        render_task t
      end
    end

    # Render single url corresponding task
    # url - The String url pathname one can be used in browser,such as
    #       '/posts','/posts/','/posts/index.html' are both valid
    # Returns the String page content
    def render_url(url)
      url=url.dup
      url[0]=''  if url[0]=='/'
      url=url+'index.html' if url.end_with? '/'
      # url=url+'/index.html' if site.url.start_with? url
      t = @tasks.detect {|t|t[:urlpath]==url}
      if t
        return render_task t,false
      end
    end

  private
    # The Hash of data_id=>url or object_id=>url
    def id2url_map
      return @id2url_map if @id2url_map
      @id2url_map=@tasks.group_by {|a| a[:id]}
      @id2url_map.merge!(@id2url_map) do |k,v|
        if v.length>1
          urls=(v.map {|a|a[:urlpath]}).join "\n\t"
          $stderr.puts "Object[#{k}] has more than one url:"
          $stderr.puts "\t#{urls}"
        end
        v[0][:urlpath]
      end
      @id2url_map
    end

    def render_task(t,write_file=true)
      item=t[:item]
      urlpath=t[:urlpath]
      template=t[:template]

      @site._cur_page_dir = File.dirname(urlpath) if @site.local

      item=Utils::ObjectProxy.new item,{site:@site} # Keep site always accessable
      erb=Tpl::LayErb.new template
      result=erb.render item

      return result unless write_file
      output_path=File.join(@site.dest,urlpath)
      dir=File.dirname output_path
      FileUtils.mkdir_p dir
      File.open(output_path,'wb') do |f|
        f.write result
      end
    end

    # Render url_pattern with context data
    # url_pattern - The String url pattern.
    # context - The Object context
    # Return url pathname
    def self.sub_url(url_pattern,context)
      url_pattern.gsub(/\{([^{}\/]+)\}/) do
        m=$1
        key_path=m.strip.split '.'
        key_path.reduce(context) do |o,key|
          v = if o.respond_to? key
                o.send key
              elsif (o.respond_to? :[])
                o[key] || o[key.to_sym]
              end
          next v if v
          raise BadUrlPatternException,"Unresolved property `#{m}` in url pattern [#{url_pattern}]!"
        end
      end
    end

    def _detectContainsPosts(item,posts)
        return posts.include? item.path if Post===item
        return posts.any? {|p|item.include? p} if PostList===item || PostListPage===item
        if Hash===item
          item.each do |k,v|
            return true if _detectContainsPosts(v,posts)
          end
        elsif Array===item
          item.each do |a|
            return true if _detectContainsPosts(a,posts)
          end
        end
        return false
    end

  end

end
