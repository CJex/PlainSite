#coding:utf-8

require 'test/unit'
require 'PlainSite/Utils'
include PlainSite::Utils
class ObjectProxyTest < Test::Unit::TestCase
  def test_proxy

    d=Demo.new
    h={ name:"XMan", age:18 , "home"=>"Earth" }
    a=ObjectProxy.new d,h

    assert a.hello==d.hello,"Call method hello"
    assert a.name==h[:name],"Get key :name"
    assert a.age==h[:age],"Get key :age"
    assert a.home==h["home"],"Get key home"
    assert a.hi==d.hi,"Call method hi"

  end

end

class Demo
  def hello
    "hello"
  end
  def hi
    "hi"
  end
end
