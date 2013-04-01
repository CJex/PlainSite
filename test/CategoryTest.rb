#coding:utf-8

require 'test/unit'
require 'fileutils'
require 'PlainSite/Data/Post'
require 'PlainSite/Data/PostList'
require 'PlainSite/Data/Category'
require 'PlainSite/Site'
include PlainSite::Data
include PlainSite

class CategoryTest < Test::Unit::TestCase
  FIXTURES_DIR=File.realpath (File.join File.dirname(__FILE__),'fixtures')
  def setup
    @site_root=File.join FIXTURES_DIR,'test-site'
    FileUtils.mkdir_p @site_root
    @site=Site.new @site_root
    @site.init_scaffold true
  end
  def teardown
    FileUtils.rm_rf @site_root
  end

  def test_category
    FileUtils.cp_r File.join(FIXTURES_DIR,'category-demo'),@site.data_path

    assert @site.data.root? == true ,'Site Root'
    assert @site.data.data_id == '' ,'Site Root'

    cat=@site.data / :'category-demo'

    assert cat,'Read category demo'
    assert cat.root? == false ,'Category should not be root'
    assert @site.data.root? ,'site.data is root'
    assert cat.display_name=='DemoDemo','Category display name'

    assert cat.has_index, 'Category has its index'

    post1=cat / :post1
    post2=cat / :post2
    assert post1.data_id=='category-demo/post1','Read post1'
    assert post2.category.data_id==cat.data_id,'Read post2'

    assert PostList===cat['*'],'Read post list'

    subs=cat.subs
    assert subs.length==2,'Sub category should be 2'

    sub1=cat['sub-category1']
    assert sub1.display_name=='Sub category1','Sub category display name'

    sub1=cat / 'sub-category1'
    assert sub1.display_name=='Sub category1','Sub category display name'


    cats=sub1.to_a
    assert cats[0].data_id==@site.data.data_id,'First should be root category'
    assert cats[1].data_id=='category-demo','Second should be category-demo category'
    assert cats[2].data_id=='category-demo/sub-category1','Third should be sub-category1 category'
    assert cats[3].nil?,'Fourth should be nil'

  end
end
