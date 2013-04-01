#coding:utf-8
module PlainSite;end
module PlainSite::Data
  require 'safe_yaml'
  require 'PlainSite/Data/Post'
  require 'PlainSite/Data/PostList'

  class ConflictNameException<Exception; end

  # The Category directory class.
  # The category directory can have its custom index post named 'index.md' or 'index.html'.
  # File '_meta.yml' under category dir decribes it's meta info attributes.
  # Supported attributes in '_meta.yml':
  #   display_name - The String category display name
  class Category
    META_FILE='_meta.yml'
    attr_reader(
      :path, # The String full path of category directory
      :relpath, # The String path of category directory relative to site.data_path
      :site,
      :index,   # The index Post
      :has_index # Bool
    )
    # path - The String category directory abspath
    # site - The Site belongs to
    def initialize(path,site)
      @path=path
      @relpath=@path[(site.data_path.length+1)..-1] || ''
      @site=site
      @is_root = @relpath==''



      # Alias of :relpath
      alias :data_id :relpath

      @index =  self / :index
      @has_index = !! @index
    end

    # whether this is the root category (aka site.data_path)
    def root?
      @is_root
    end

    # Return parent category or nil if self is root
    def parent
      return @parent if @parent
      return nil if root?
      @parent=if @relpath['/']
                Category.new File.join(@site.data_path,File.dirname(@relpath)),@site
              else
                Category.new @site.data_path,@site
              end
    end

    # Return parent categories array
    def parents
      return @parents if @parents
      @parents=[]
      return @parents if root?
      cat=self
      while cat=cat.parent
        @parents.unshift cat
      end
      @parents
    end


    # Query data tree
    # path - The String|Symbol *relative* path of post or category,
    #    It can be an exact file path,or a category/slug path.
    #    For examples,both 'essay/2011-11-11-live-happy.md' and 'essay/live-happy' are valid.
    #    '*' Retrieve all posts under this category.
    #        (But excludes its index post and includes sub category index posts).
    #    '**' retrieve recursively all posts under this category(include index posts)
    #    Category path(directory),example 'esssay',will return a new child Category .
    #    Category path ends with '/*',will return posts array under the category dir.
    #    Category path end with '/**',will return all posts under the category dir recursively.
    # Return
    #    The sub Category  when path is a category path
    #    The PostList when path is category path end with '/*' or '/**'
    #    The Post when path is a post path
    def [](path)
      path=path.to_s
      if path['/']
        return path.split('/').reduce(self)  {|cat,p| cat && cat[p]}
      end

      return posts if path=='*'
      return sub_posts if path=='**'
      get_sub path or get_post path

    end
    alias :/ :[]

    # Get post by slug or filename
    # p - The String post slug or filename
    # Return the Post or nil when not found
    def get_post(p)
      if p.to_sym==:index
        p=(Post.extnames.map {|t|"index.#{t}"}).detect do |f|
          File.exists? (File.join @path,f)
        end
      end
      return nil unless p
      if p['.'] # filename
        post_path=File.join @path,p
        if (File.exists? post_path) && (File.basename(post_path)[0]!='_')

          return Post.new post_path,@site
        end
      end
      return posts_map[p] if posts_map.has_key? p
    end

    # The posts under this category,but exclude its index post.
    # Not contains the sub category's posts but include sub category's index post.
    # Default sort by date desc,slug asc
    # Return PostList
    def posts
      return @posts if @posts

      posts=Dir.glob(@path+'/*')
      posts.select! do |f|
        if File.basename(f)[0]=='_'
          false
        elsif File.directory? f # if directory has an index
          (Category.new f,@site).has_index
        else
          (File.file? f) && (Post.extname_ok? f) &&
            ((File.basename f,(File.extname f))!='index') # exclude index post
        end
      end

      return @posts=PostList.new([],@site) if posts.empty?

      posts.map! {|f| Post.new f,@site}

      @posts=PostList.new posts,@site
    end


    # Get all posts under category recursively(include all index posts)
    # Return PostList
    def sub_posts
      return @sub_posts if @sub_posts
      all_posts=posts.to_a
      subs.each do |c|
        all_posts.concat c.sub_posts.to_a
      end
      all_posts.push @index if @has_index && root?
      @sub_posts=PostList.new all_posts,@site
    end

    # Get the sub categories
    # Return Category[]
    def subs

      return @subs if @subs
      subs=Dir.glob @path+'/*'
      subs.select! { |d| File.basename(d)[0]!='_' && (File.directory? d) }
      subs.map! { |d| Category.new d,@site }

      @subs=subs
    end

    # Get the sub category
    # sub_path The String path relative to current category
    # Return Category or nil
    def get_sub(sub_path)
      return nil if sub_path[0]=='_'
      sub_path=File.join @path,sub_path
      if File.directory? sub_path
        Category.new sub_path,@site
      end
    end


    # The Hash map of slug=>post
    # Return Hash
    def posts_map
      return @posts_map if @posts_map

      group=posts.group_by &:slug

      conflicts=group.reject {|k,v| v.length==1} #Filter unconflicts
      unless conflicts.empty?
        msg=(conflicts.map {|slug,v|
          "#{slug}:\n\t"+(v.map &:path).join("\n\t")
        }).join "\n"
        raise ConflictNameException,"These posts use same slug:#{msg}"
      end

      group.merge!(group) {|k,v| v[0] }
      @posts_map=group
    end

    # Get the meta info in category path ./_meta.yml
    def meta_info
      return @meta_info if @meta_info
      meta_file=File.join(@path,META_FILE)
      if File.exists? meta_file
        @meta_info = YAML.safe_load_file meta_file
      else
        @meta_info= {}
      end
    end

    # The String category dir name,root category's name is empty string
    def name
      return @name unless @name.nil?
      @name=File.basename(data_id)
    end

    def display_name
      return @display_name unless @display_name.nil?
      @display_name=  if meta_info['display_name'].nil?
                        name.gsub(/-|_/,' ').capitalize
                      else
                        meta_info['display_name']
                      end
    end

    def to_s
      'Category:'+(@relpath.empty? ? '#root#' : @relpath)
    end
    alias :to_str :to_s

    def to_a
      parents+[self]
    end
    alias :to_ary :to_a
  end # end class Category
end # end PlainSite::Data
