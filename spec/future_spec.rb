#!/usr/bin/env ruby


$LOAD_PATH << "lib"
$LOAD_PATH << "../lib"

require "future"

require "rubygems"
require "spec"

require "timeout"

class TestObject
	@@result = []

	def result
		ret = @@result.dup
		@@result.clear
		ret
	end

	def heavy(n, value, &block)
		sleep n
		@@result << [n, value]
		if block_given?
			yield
		else
			value
		end
	end
end

describe Future do
	before do
		@o = TestObject.new
	end

	it "should handle message asynchronously" do
		future = nil

		timeout(0.1) do
			future = Future.new(Kernel, :sleep, [ 0.5 ], nil)
		end

		Proc.new {
			timeout(0.1) do
				future.inspect
			end
		}.should raise_error(Timeout::Error)

		future.inspect # block

		Proc.new {
			timeout(0.1) do
				future.inspect
			end
		}.should_not raise_error(Timeout::Error)
	end

	it "should append async mehtod to Object" do
		# normal
		@o.heavy(0.1, :foo)
		@o.result.should == [ [0.1, :foo] ]

		# async
		future = @o.async(:heavy, 0.1, :foo)
		@o.result.should == [ ]
		future.inspect.should == ":foo"
		@o.result.should == [ [0.1, :foo] ]

		# async object
		future = @o.async.heavy(0.1, :foo)
		@o.result.should == [ ]
		future.inspect.should == ":foo"
		@o.result.should == [ [0.1, :foo] ]
	end

	it "should handle block correctly" do
		future = @o.async(:heavy, 0.1, :foo) {
			:bar
		}
		@o.result.should == [ ]
		future.inspect.should == ":bar"
		@o.result.should == [ [0.1, :foo] ]
	end
end

