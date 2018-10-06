
class VarInt::LEB128::NonRedundant <  VarInt::LEB128
	def self.do_encode_unsigned( i )
		loop {
			b = (i & 0x7F).to_u8
			i >>= 7
			yield( ((i!=0)?0x80_u8:0x00_u8) | b )
			if i == 0
				return
			else
				i -= 1
			end
		}
	end

	def self.decode_unsigned_UInt64( io : IO )
		result : UInt64 = 0_u64
		bytes : UInt32 = 0
		loop {
			if !(b=io.read_byte).nil?
				result += ( b & 0x7F ).to_u64 << (bytes*7)
				bytes += 1
				return {result,bytes} if (b&0x80) != 0x80
				result += 1.to_u64 << (bytes*7)
			else
				return {result,bytes}
			end
		}
	end
	def self.decode_unsigned_bigint( io : IO )
		result = BigInt.new(0)
		bytes : UInt32 = 0
		loop {
			if !(b=io.read_byte).nil?
				result += ( b & 0x7F ).to_big_i << (bytes*7)
				bytes += 1
				return {result,bytes} if (b&0x80) != 0x80
				result += 1.to_big_i << (bytes*7)
			else
				return {result,bytes}
			end
		}
	end

	def self.encode_unsigned( i )
		res = [] of UInt8
		self.do_encode_unsigned(i) {|byte| res.push(byte) }
		return res
	end
	def self.encode_unsigned( i, io : IO )
		self.do_encode_unsigned(i) {|byte| io.write_byte byte }
	end

	def self.encode_signed( i : Int64 | Int32 | Int16 | Int8 | BigInt ) : Array(UInt8)
		res = [] of UInt8
		loop {
			b = (i & 0x7F).to_u8
			i >>= 7
			done = ( i == 0 || i == -1 )
			res.push( ( !done ? 0x80_u8 : 0x00_u8 ) | b )
			if done
				return res
			else
				i += ( i<0 ? -1 : 1 )
			end
		}
	end
end
