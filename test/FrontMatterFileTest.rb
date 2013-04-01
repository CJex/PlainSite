#coding:utf-8

require 'test/unit'
require 'PlainSite/Data/FrontMatterFile'
include PlainSite::Data
class FrontMatterFileTest < Test::Unit::TestCase
  FIXTURES_DIR=File.realpath (File.join File.dirname(__FILE__),'fixtures')
  def test_valid

    valid_file=File.join FIXTURES_DIR,'valid-front-matter.html'
    tags=['Python','Ruby','Java','Haskell']
    f=FrontMatterFile.new valid_file

    assert f.headers['name']=='valid','Valid header :name'
    assert f.headers['title']=='Hello, World!','Valid header :title'
    assert f.headers['tags']==tags,'Valid header :tags'
    assert f.headers['xxx'].nil?,'Absent header nil'

    assert f.content=='CONTENT','Valid content'
  end

  def test_invalid
    invalid_file=File.join FIXTURES_DIR,'invalid-front-matter.html'

    assert_raise InvalidFrontMatterFileException do
      f=FrontMatterFile.new invalid_file
      f.headers
    end
  end

  def test_no_front
    no_front_file=File.join FIXTURES_DIR,'no-front-matter.html'

    assert_raise InvalidFrontMatterFileException do
      f=FrontMatterFile.new no_front_file
      f.headers
    end

  end
end
