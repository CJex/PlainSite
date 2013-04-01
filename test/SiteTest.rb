#coding:utf-8

require 'test/unit'
require 'fileutils'
require 'set'
require 'PlainSite/Site'
require 'git'
require 'open3'
include PlainSite

class SiteTest < Test::Unit::TestCase
  FIXTURES_DIR=File.realpath (File.join File.dirname(__FILE__),'fixtures')

  def setup
    @site_root=Dir.mktmpdir 'test-site-'
    @pwd = Dir.pwd
  end
  def teardown
    FileUtils.rm_rf @site_root
    Dir.chdir @pwd
  end

  def test_diff_build
    site=Site.new @site_root
    site.init_scaffold true

    to_del_post=site.newpost 'essays/git-delete-test1','Git Test 1'
    to_mod_post=site.newpost 'essays/git-mod-test2','Git Test 2'
    includes=[]
    includes.push (site.newpost 'essays/include-test1','Include Test')
    includes.push (site.newpost 'essays/include-test2','Include Test')
    includes.push (site.newpost 'essays/include-test3','Include Test')


    Dir.chdir @site_root

    Dir.chdir @site_root # `cd #{@site_root}` wont work on fucking MSWindows different partitions
    `git init`
    `git add .`
    `git commit -m Init`


    FileUtils.rm to_del_post
    File.open(to_mod_post,'wb') {|f| f.write "---\ntitle: Modified\n---\n Modified!"}
    new_post=site.newpost 'essays/git-untracked','Git Test Untracked'

    added_template=File.join site.templates_path,'test.html'
    File.open(added_template,'wb') {|f| f.write 'TEST Template'}

    `git add #{added_template}`


    files=site.diff_files includes


    assert [to_mod_post,new_post].to_set <= files[:updated_posts].to_set ,"Should include new and modified posts"
    assert files[:has_deleted_posts], "Should had deleted posts"

    assert (files[:updated_templates].include? added_template), "Should include added template"

    assert includes.to_set <= files[:updated_posts].to_set ,"Should force include includes-posts"

    site.build(all:true)

  end

  def test_build
    site=Site.new @site_root
    site.init_scaffold true


    site.data.subs.each do |cat|
      20.times do |i|
        name="2014-#{rand 1..12}-#{rand 1..28 }-hello-post#{i}.md"
        path=File.join cat.path,name
        File.open(path,'wb') do |f|
          s= <<-CONTENT
---
title: Hello,post#{i}
---

**Content here!**

Category: <a href="<%=URI.join site.url,"#{cat.data_id}"%>">#{cat.display_name}</a>


<highlight python>
def hello(name):
  print "Hello,%s" % name

if __name__=='__main__':
  hello("World!")
</highlight>
CONTENT
          f.write s
        end
      end
    end


    site.build(dest:@site_root,local:true)
    #puts "\n#{@site_root}\n"
    #site.serve
  end
end
