# TODO: Write documentation for `VarInt`
module VarInt
  VERSION = "0.1.0"

  # TODO: Put your code here

  def self.encode_unsigned( i )
  	raise "Signed integers not supported by encode_unsigned" if i < 0
  	a = [] of UInt8
	a.push( 0x7F_u8 & i )
	i >>= 7
	while i > 0
		a.push( 0x80_u8 | ( i & 0x7F ) )
		i >>= 7
	end

	s = Bytes.new(a.size,0)
	a.each_with_index {|b,i| s[a.size-i-1] = b }
	return s
  end
  def self.decode_unsigned( bytes : Bytes )
  	return self.decode_unsigned( IO::Memory.new(bytes,false) )
  end
  def self.decode_unsigned( io : IO ) : Tuple(UInt64,UInt32)
  	i = 0_u64
	bytes = 0_u32

	loop {
		if !(b=io.read_byte).nil?
			i = (i << 7) | 0x7F_u64 & b
			bytes += 1
			return {i,bytes} if (0x80_u8 & b) != 0x80_u8
		else
			return {i,bytes}
		end
	}
  end
  def self.decode_unsigned_bigint( io : IO ) : Tuple(BigInt,UInt32)
  	i = BigInt.new(0)
	bytes = 0_u32

	loop {
		if !(b=io.read_byte).nil?
			i = (i << 7) | 0x7F & b
			return {i,bytes} if (0x80_u8 & b) != 0x80_u8
		else
			return {i,bytes}
		end
	}
  end
end
