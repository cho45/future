
class Future
	def initialize(obj, name, args, block)
		@obj, @name, @args, @block = obj, name, args, block
		@th  = Thread.start do
			Thread.pass # 一応明示的に pass しておく
			@obj.send(@name, *@args, &@block)
		end
	end

	def method_missing(name, *args, &block)
		@th.value.send(name, *args, &block)
	end

	# 全部委譲してなりすます
	Object.instance_methods.each do |m|
		next if %w|__send__ __id__ object_id|.include? m.to_s
		undef_method m
	end

	module ObjectExtension
		def async(name=nil, *args, &block)
			name ? Future.new(self, name, args, block) : AsyncObject.new(self)
		end

		class AsyncObject
			def initialize(obj)
				@obj = obj
			end

			def method_missing(name, *args, &block)
				Future.new(@obj, name, args, block)
			end

			Object.instance_methods.each do |m|
				next if %w|__send__ __id__ object_id|.include? m.to_s
				undef_method m
			end
		end
	end
end

class Object
	include Future::ObjectExtension
end

