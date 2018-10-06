require "spec"
require "../src/varint"

class Array(T)
	def to_slice()
		return Slice(T).new(0,0) if self.size == 0
		slice = Slice(T).new(size,self[0])
		self.each_with_index {|v,i| slice[i] = v }
		return slice
	end
end
