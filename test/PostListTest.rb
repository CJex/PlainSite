#coding:utf-8

require 'test/unit'
require 'grit'
require 'fileutils'
require 'PlainSite/Site'
include PlainSite

class PostListTest < Test::Unit::TestCase
  def setup
    @site_root=Dir.mktmpdir 'test-site-'
  end
  def teardown
    FileUtils.rm_rf @site_root
  end

  def test_list
    site=Site.new @site_root
    site.init_scaffold true

    posts_path=[]

    site.data.subs.each do |cat|
      File.delete *(Dir.glob cat.path+'/*')
      12.times do |i|
        name="2012-#{i+1}-22-hello-#{cat.name}-#{i+1}.md"
        path=File.join cat.path,name
        posts_path.push path
        File.open(path,'wb') do |f|
          f.write "---\ntitle: Hello,#{cat.name},#{i+1}\n---\n XXX"
        end
      end
    end

    pages=site.data / :essays / '*' / 5

    assert pages[0].next_page.nil?,"Should first page's next_page be nil"
    assert pages[0].posts.length==5,"Page size should be 5"
    pages[0].posts.each_with_index do |p,i|
      d=Date.new 2012,12-i,22
      assert p.date == d,"Date should be #{d}"
    end


    all_posts=site.data['**']
    one_page=(all_posts/100).first

    posts_path.each do |p|
      assert (all_posts.include? p),"Should PostList include post:#{p}"
      assert (one_page.include? p),"Should PostListPage include post:#{p}"
    end


  end
end
