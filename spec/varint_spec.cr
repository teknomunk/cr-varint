require "./spec_helper"
require "big"

describe VarInt do
  # TODO: Write tests

  describe "#encode_unsigned" do
  	it "encodes 1 byte integers" do
		0x7F.times {|i|
			VarInt::MSB.encode_unsigned(i).should eq( Bytes.new(1,i.to_u8) )
		}
	end
  end
  describe "#decode_unsigned" do
  	it "decodes 1 byte integers" do
		0x7F.times {|i|
			VarInt::MSB.decode_unsigned( Bytes.new(1,i.to_u8) ).should eq({i.to_u64,1_u32})
		}
	end
	it "decodes examples" do
		VarInt::MSB.decode_unsigned( ([0x00] of UInt8).to_slice ).should eq({0_u64,1_u32}) 
		VarInt::MSB.decode_unsigned( ([0x7F] of UInt8).to_slice ).should eq({0x7F_u64,1_u32}) 
		VarInt::MSB.decode_unsigned( ([0x81,0x00] of UInt8).to_slice ).should eq({0x80_u64,2_u32}) 
		VarInt::MSB.decode_unsigned( ([0xC0,0x00] of UInt8).to_slice ).should eq({0x2000_u64,2_u32}) 
		VarInt::MSB.decode_unsigned( ([0xFF,0x7F] of UInt8).to_slice ).should eq({0x3FFF_u64,2_u32}) 
		VarInt::MSB.decode_unsigned( ([0x81,0x80,0x00] of UInt8).to_slice ).should eq({0x4000_u64,3_u32}) 
		VarInt::MSB.decode_unsigned( ([0xFF,0xFF,0x7F] of UInt8).to_slice ).should eq({0x1FFFFF_u64,3_u32}) 
		VarInt::MSB.decode_unsigned( ([0x81,0x80,0x80,0x00] of UInt8).to_slice ).should eq({0x200000_u64,4_u32}) 
		VarInt::MSB.decode_unsigned( ([0xC0,0x80,0x80,0x00] of UInt8).to_slice ).should eq({0x8000000_u64,4_u32}) 
		VarInt::MSB.decode_unsigned( ([0xFF,0xFF,0xFF,0x7F] of UInt8).to_slice ).should eq({0xFFFFFFF_u64,4_u32}) 
	end
  end
end
