#coding:utf-8

require 'test/unit'
require 'PlainSite/Tpl/LayErb'
include PlainSite::Tpl

class LayErbTest < Test::Unit::TestCase
  FIXTURES_DIR=File.realpath (File.join File.dirname(__FILE__),'fixtures')
  def test_render
    tpl=File.join(FIXTURES_DIR,'tpl.erb')
    erb=LayErb.new tpl
    context={
      code: "some_text"
    }
    result=erb.render context
    except="<body>Included:some_text&lt;html&gt;</body>"
    assert result.strip==except,'Tpl render with include and layout'

  end
end
