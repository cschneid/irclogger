require File.dirname(__FILE__) + '/../lib/sinatra'

require 'rubygems'
require 'test/spec'

context "Simple Events" do

  def simple_request_hash(method, path)
    Rack::Request.new({
      'REQUEST_METHOD' => method.to_s.upcase,
      'PATH_INFO' => path
    })
  end

  def invoke_simple(path, request_path, &b)
    event = Sinatra::Event.new(path, &b)
    event.invoke(simple_request_hash(:get, request_path))
  end
  
  specify "return last value" do
    block = Proc.new { 'Simple' }
    result = invoke_simple('/', '/', &block)
    result.should.not.be.nil
    result.block.should.be block
    result.params.should.equal Hash.new
  end
  
  specify "takes params in path" do
    result = invoke_simple('/:foo/:bar', '/a/b')
    result.should.not.be.nil
    result.params.should.equal "foo" => 'a', "bar" => 'b'
    
    # unscapes
    result = invoke_simple('/:foo/:bar', '/a/blake%20mizerany')
    result.should.not.be.nil
    result.params.should.equal "foo" => 'a', "bar" => 'blake mizerany'
  end
  
  specify "ignores to many /'s" do
    result = invoke_simple('/x/y', '/x//y')
    result.should.not.be.nil
  end
  
  specify "understands splat" do
    invoke_simple('/foo/*', '/foo/bar').should.not.be.nil
    invoke_simple('/foo/*', '/foo/bar/baz').should.not.be.nil
    invoke_simple('/foo/*', '/foo/baz').should.not.be.nil
  end  
          
end
