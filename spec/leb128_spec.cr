require "./spec_helper"
require "big"

describe VarInt::LEB128 do
	it "encodes UInt8 values" do
		VarInt::LEB128.encode(0x00_u8).should eq([0x00_u8])
		1.times {|i|
			VarInt::LEB128.encode((0x01_u8<<(i*7+7))-1).should eq([0xFF_u8]*(i) + [0x7F_u8])
			VarInt::LEB128.encode(0x01_u8<<(i*7+7)).should eq([0x80_u8]*(i+1) + [0x01_u8])
		}
	end
	it "encodes UInt16 values" do
		VarInt::LEB128.encode(0x0000_u16).should eq([0x00_u8])
		2.times {|i|
			VarInt::LEB128.encode((0x01_u16<<(i*7+7))-1).should eq([0xFF_u8]*(i) + [0x7F_u8])
			VarInt::LEB128.encode(0x01_u16<<(i*7+7)).should eq([0x80_u8]*(i+1) + [0x01_u8])
		}
		VarInt::LEB128.encode(0xFFFF_u16).should eq([0xFF_u8,0xFF_u8,0x03_u8])
	end
	it "decodes values" do
		bytes = Bytes.new(2,0)
		bytes[0] = 0x88
		bytes[1] = 39
		value,bytes = VarInt::LEB128.decode_unsigned_int(bytes)
		value.should eq(5000)
		bytes.should eq(2)
	end
	it "encodes UInt32 values" do
		VarInt::LEB128.encode(0x00000000_u32).should eq([0x00_u8])
		4.times {|i|
			VarInt::LEB128.encode((0x01_u32<<(i*7+7))-1).should eq([0xFF_u8]*(i) + [0x7F_u8])
			VarInt::LEB128.encode(0x01_u32<<(i*7+7)).should eq([0x80_u8]*(i+1) + [0x01_u8])
		}
		VarInt::LEB128.encode(0xFFFFFFFF_u32).should eq([0xFF_u8,0xFF_u8,0xFF_u8,0xFF_u8,0x0F_u8])
		VarInt::LEB128.encode( 624485 ).should eq([0xE5_u8,0x8E_u8,0x26_u8])
	end
	it "encodes UInt64 values" do
		VarInt::LEB128.encode(0x0000000000000000_u64).should eq([0x00_u8])
		9.times {|i|
			VarInt::LEB128.encode((0x01_u64<<(i*7+7))-1).should eq([0xFF_u8]*(i) + [0x7F_u8])
			VarInt::LEB128.encode(0x01_u64<<(i*7+7)).should eq([0x80_u8]*(i+1) + [0x01_u8])
		}
		VarInt::LEB128.encode(0xFFFFFFFFFFFFFFFF_u64).should eq([0xFF_u8]*9+[0x01_u8])
	end
	it "encodes BigInt values" do
		res = VarInt::LEB128.encode_unsigned(BigInt.new("123456789012345678901234567890"))
		res.should eq([210_u8, 149_u8, 252_u8, 241_u8, 228_u8, 157_u8, 248_u8, 185_u8, 195_u8, 
			237_u8, 191_u8, 200_u8, 238_u8, 49_u8])
	end
	it "decodes BigInt values" do
		slice = Bytes.new(14,0)
		[210_u8, 149_u8, 252_u8, 241_u8, 228_u8, 157_u8, 248_u8, 185_u8, 195_u8, 
		 237_u8, 191_u8, 200_u8, 238_u8, 49_u8].each_with_index {|i,idx| slice[idx] = i }
		
		num,bytes = VarInt::LEB128.decode_unsigned_bigint(IO::Memory.new(slice))
		num.should eq(BigInt.new("123456789012345678901234567890"))
		bytes.should eq(14)
	end

	it "encodes Int8 values" do
		VarInt::LEB128.encode(-1).should eq([0x7F_u8])
	end
	it "encodes Int32 values" do
		VarInt::LEB128.encode(-424091).should eq([0xE5_u8,0x8E_u8,0x66_u8])
	end
	it "encodes values to IO" do
		VarInt::LEB128.encode(5000, io=IO::Memory.new() )
		slice = io.to_slice
		slice.size.should eq(2)
		slice[0].should eq(0x88_u8)
		slice[1].should eq(39_u8)
	end
	describe VarInt::LEB128::Limited64 do
	end
	describe VarInt::LEB128::NonRedundant do
		it "encodes UInt8 values" do
			VarInt::LEB128::NonRedundant.encode(0x00_u8).should eq([0x00_u8])
			VarInt::LEB128::NonRedundant.encode(0x7F_u8).should eq([0x7F_u8])
			VarInt::LEB128::NonRedundant.encode(0x80_u8).should eq([0x80_u8,0x00_u8])
			VarInt::LEB128::NonRedundant.encode(0xFF_u8).should eq([0xFF_u8,0x00_u8])

			VarInt::LEB128::NonRedundant.encode(-1_i8).should eq([0x7F_u8])
			VarInt::LEB128::NonRedundant.encode(-2_i8).should eq([0x7E_u8])
			#VarInt::LEB128::NonRedundant.encode(-125_i8).should eq([0x_u8])
		end
		it "encodes UInt16 values" do
			
		end
		it "encodes values to IO" do
			VarInt::LEB128::NonRedundant.encode(5000, io=IO::Memory.new() )
			slice = io.to_slice
			slice.size.should eq(2)
			slice[0].should eq(0x88_u8)
			slice[1].should eq(38_u8)
		end
		it "encodes BigInt values" do
			res = VarInt::LEB128::NonRedundant.encode_unsigned(BigInt.new("123456789012345678901234567890"))
			res.should eq([210_u8, 148_u8, 251_u8, 240_u8, 227_u8, 156_u8, 247_u8, 184_u8, 194_u8, 
				236_u8, 190_u8, 199_u8, 237_u8, 48_u8])
		end
		it "decodes UInt64 values" do
			slice = [0x80_u8,0x00_u8].to_slice
			num,bytes = VarInt::LEB128::NonRedundant.decode_unsigned_UInt64(IO::Memory.new(slice))
			num.should eq(0x80)
			bytes.should eq(2)
		end
		it "decodes BigInt values" do
			#slice = Bytes.new(14,0)
			#[210_u8, 148_u8, 251_u8, 240_u8, 227_u8, 156_u8, 247_u8, 184_u8, 194_u8, 
			# 236_u8, 190_u8, 199_u8, 237_u8, 48_u8].each_with_index {|i,idx| slice[idx] = i }
			slice = [210_u8, 148_u8, 251_u8, 240_u8, 227_u8, 156_u8, 247_u8, 184_u8, 194_u8, 
			 236_u8, 190_u8, 199_u8, 237_u8, 48_u8].to_slice
			
			num,bytes = VarInt::LEB128::NonRedundant.decode_unsigned_bigint(IO::Memory.new(slice))
			num.should eq(BigInt.new("123456789012345678901234567890"))
			bytes.should eq(14)
		end
	end
end
