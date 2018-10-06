# Special case for numbers known to fit into 64 bits: 9 bytes can be used instead of 10 to encode largest numbers
class VarInt::LEB128::Limited64
	def self.encode( i : UInt32|UInt16|UInt8|Int32|Int16|Int8 )
		self.encode_UInt64( i.to_u64 )
	end
	def self.encode( i : UInt64 ) : Array(UInt8)
		res = [] of UInt8
		8.times {
			b = i & 0x7F
			i >>= 7
			res.push( ((i!=0)?0x80_u8:0x00_u8) | b )
			return res if( i == 0 )
		}
		res.push( (i&0xFF).to_u8 )
		return res
	end
	def self.decode( ptr : Bytes ) : {UInt64,UInt8}
		bytes : UInt8 = 1
		result : UInt64 = 0
		8.times {|i|
			result |= ( ptr[i] & 0x7F ).to_u64 << (i*7)
			return {result,bytes.to_u8} if ptr[i] & 0x80 == 0
			bytes += 1
		}
		result |= ptr[8] << 56
		return {result,9.to_u8}
	end
	def self.encode( i : Int64 ) : Array(UInt8)
		raise "TODO: implement"
	end
	def self.encode_float( f : Float64 ) : Array(UInt8)
		return self.encode(LEB128.float64_to_vfloat(f))
	end
end
