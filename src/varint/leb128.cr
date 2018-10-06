require "big"

class VarInt::LEB128
	alias UInt = UInt64 | UInt32 | UInt16 | UInt8
	alias SInt = Int64 | Int32 | Int16 | Int8

	def self.encode( i : UInt )
		self.encode_unsigned( i )
	end
	def self.encode( i : UInt, io : IO )
		self.encode_unsigned( i, io )
	end

	# Unsigned integers
	def self.do_encode_unsigned( i : UInt | BigInt )
		loop {
			b = (i & 0x7F).to_u8
			i >>= 7
			yield( ((i!=0)?0x80_u8:0x00_u8) | b )
			return if i == 0
		}
	end
	def self.decode_unsigned_int( bytes : Bytes ) : Tuple(UInt64,UInt32)
		self.decode_unsigned_int( IO::Memory.new(bytes,false) )
	end
	def self.decode_unsigned_int( io : IO ) : Tuple(UInt64,UInt32)
		result : UInt64 = 0
		bytes : UInt32 = 0
		loop {
			if !(b=io.read_byte).nil?
				result |= ( b & 0x7F ).to_u64 << (bytes*7)
				bytes += 1
				return {result,bytes} if (b&0x80) != 0x80
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
				result |= ( b & 0x7F ).to_big_i << (bytes*7)
				bytes += 1
				return {result,bytes} if (b&0x80) != 0x80
			else
				return {result,bytes}
			end
		}
	end
	def self.encode_unsigned( i : UInt | BigInt, io : IO )
		self.do_encode_unsigned( i ) {|byte| io.write_byte byte }
	end
	def self.encode_unsigned( i : UInt | BigInt ) : Array(UInt8)
		res = [] of UInt8
		self.do_encode_unsigned( i ) {|byte| res.push(byte) }
		return res
	end

	# Signed integers
	def self.encode( i : SInt ) : Array(UInt8)
		self.encode_signed(i)
	end
	def self.encode_signed( i : SInt | BigInt ) : Array(UInt8)
		res = [] of UInt8
		loop {
			b = (i & 0x7F).to_u8
			i >>= 7
			done = ( i == 0 || i == -1 )
			res.push( ( !done ? 0x80_u8 : 0x00_u8 ) | b )
			return res if done
		}
	end

     def self.encode( f : Float64 ) : Array(UInt8)
		self.encode_float64(f)
	end
	def self.encode_float64( f : Float64 ) : Array(UInt8)
		return self.encode( self.float64_to_vfloat(f) )
	end

	private lib Library
		union IntOrFloat
			f : Float64
			i : UInt64
		end
	end
	def self.float64_to_vfloat( f : Float64 )
		iof = Library::IntOrFloat.new
		iof.f = f
		num = iof.i

		sign = ( num >> 63 ) & 1
		exp = ( num >> 52 ) & ( (1<<11) - 1 )
		mant = num & ((1<<52)-1)

		# Convert the exponent to sign+magnitude format
		if( exp >= 1023 )
			exp_sign = 0
			exp_mag = exp - 1023
		else
			exp_sign = 1
			exp_mag = 1022 - exp
		end
		# Calculate the number of significant bits
		#sig_fig = 0
		#text.each_byte {|b| sig_fig += 1 if( b >= 48 && b <= 57 ) }
		#bits = ((( Math.log(10) / Math.log(2) ) * sig_fig).ceil + 1).to_i32

		# Mask off the lower, unsignificant bits
		#mant &= ~( (1<<(52-bits)) - 1 ) 

		res = (
			( ( sign << 6 ) | ( exp_sign << 5 ) | ( ( exp_mag & 3 ) << 3 ) | ( (mant >> 49 ) & 7 ) ) << 7*0 |
			( ( (exp_mag>>2) & 3 ) | ( ( mant >> 44 ) & ((1<<5)-1) ) ) << 7*1 |
			( ( (exp_mag>>4) & 3 ) | ( ( mant >> 39 ) & ((1<<5)-1) ) ) << 7*2 |
			( ( (exp_mag>>6) & 3 ) | ( ( mant >> 34 ) & ((1<<5)-1) ) ) << 7*3 | 
			( ( (exp_mag>>8) & 3 ) | ( ( mant >> 29 ) & ((1<<5)-1) ) ) << 7*4 |
			( (mant>>22) & ((1<<7)-1) ) << 7*5 |
			( (mant>>15) & ((1<<7)-1) ) << 7*6 |
			( (mant>>8) & ((1<<7)-1) ) << 7*7 |
			( (mant&0xFF) ) << 7*8 | 
			0
		)
	end
end

require "./leb128/*"
