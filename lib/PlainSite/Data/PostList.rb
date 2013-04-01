#coding:utf-8
module PlainSite;end
module PlainSite::Data
  require 'PlainSite/Data/Post'
  require 'PlainSite/Data/PostListPage'
  class PostList
    include Enumerable
    # PostList,default sort by date desc and by name asc
    # posts - The Post[]|String[] of posts or posts file path(abs or relative to site.data_path) array
    # site - The Site
    def initialize(posts,site)
      if String===posts[0]
        @posts=posts.map {|f| Post.new f,site }
      else
        @posts=posts.map &:dup
      end
      @posts.sort! do |a,b|
        # sort by date desc and by name asc
        [b.date,a.slug] <=> [a.date,b.slug]
      end
      @site=site
      @custom_index= @posts.any? &:is_index
    end

    # Array like slice method
    # Return the Post or slice PostList
    def [](*args)
      if args.length==1
        i=args[0]
        if Range===i
          posts=@posts[i]
          return nil if posts.nil? || posts.empty?
          PostList.new posts,@site
        else
          post=@posts[i]
          if post
            post.next_post= i-1 < 0 ? nil : @posts[i-1] # Because -1 will index from last
            post.prev_post= @posts[i+1]
          end
          post
        end
      else
        start,len=args
        posts=@posts[start,len]
        return nil if posts.nil? || posts.empty?
        PostList.new posts,@site
      end
    end
    alias :slice :[]

    # Paginate post list
    # This is a smart paginater. Version Control System friendly!
    # What's VCS friendly? It's page nums use a revert order.
    # The old the page's date is,the smaller the page's num is.
    # Options:
    #   page_size - The Integer page size number,must be more than zero,default is 10
    #   revert_nos - The Boolean value to control if use revert order page num,default is true
    # Return: The PostListPage[]
    def paginate(opts={})
      revert_nos=opts[:revert_nos].nil? ? true : opts[:revert_nos]
      page_size=opts[:page_size] || 10
      total=@posts.length
      return [] if total==0

      # In revert nos case,the first page need padding to fit full page
      if revert_nos && total>page_size
        start=total % page_size
        pages=[self.slice(0,page_size)]
      else
        start=0
        pages=[]
      end

      while posts=self.slice(start,page_size)
        pages.push posts
        start+=page_size
      end

      nos_list=(1..pages.length).to_a
      display_nums=nos_list.dup
      slugs=('a'..'zzz').take pages.length # Use letters id instead of numbers

      if revert_nos
        nos_list.reverse!
        slugs.reverse!
      end
      slugs[0]='index' unless @custom_index # Category has its custom index post

      total_pages_count=pages.length
      pages= pages.zip(nos_list,display_nums,slugs).map do |a|
        posts,num,display_num,slug=a
        PostListPage.new(
          # num: num,  # It's useles
          slug: slug, display_num: display_num,
          posts: posts, site: @site,
          total_pages_count: total_pages_count,
          total_posts_count: total,
          page_size: page_size,
          revert_nos: revert_nos
        )
      end

      next_pages=[nil]+pages[0..-2]
      prev_pages=(pages[1..-1] or [])+[nil]
      pages.zip(prev_pages,next_pages) do |a|
        page,prev_page,next_page=a
        page.prev_page=prev_page
        page.next_page=next_page
        page.all_pages=pages
      end

      pages
    end

    # Install B
    # `posts / 5`  is same as `posts.paginate(page_size:5)`
    def /(page_size)
      paginate(page_size:page_size)
    end

    def +(other)
      raise TypeError,"Except #{PostList} Type" unless PostList===other
      PostList.new @posts+other.to_a
    end

    # Check if contains one post
    # p - The Post object or the String path or relpath or data_id of post
    def include?(p)
      if Post===p
        return @posts.include? p
      end
      return @posts.any? {|post| post.path==p || post.relpath==p || post.data_id==p}
    end

    def length
      @posts.length
    end

    def empty?
      length==0
    end

    def each(&block)
      block_given? or return enum_for __method__
      0.upto @posts.length-1 do |i|
        yield self[i]
      end
    end

    def to_a
      @posts.dup
    end
    alias :to_ary :to_a

    %w(drop drop_while find_all select reject sort sort_by take take_while).each do |method|
      define_method(method) do |*args,&block|
        ary=super *args,&block
        if ary
          PostList.new ary.to_a,@site
        end
      end
    end
  end
end
