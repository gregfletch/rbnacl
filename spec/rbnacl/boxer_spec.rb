require 'spec_helper'

describe Crypto::Boxer do
  let (:alicepk) { "\x85 \xF0\t\x890\xA7Tt\x8B}\xDC\xB4>\xF7Z\r\xBF:\r&8\x1A\xF4\xEB\xA4\xA9\x8E\xAA\x9BNj"  } # from the nacl distribution
  let (:bobsk) { "]\xAB\b~bJ\x8AKy\xE1\x7F\x8B\x83\x80\x0E\xE6o;\xB1)&\x18\xB6\xFD\x1C/\x8B'\xFF\x88\xE0\xEB" } # from the nacl distribution
  let (:alice_key) { Crypto::PublicKey.new(alicepk) }
  let (:bob_key) { Crypto::SecretKey.new(bobsk) }

  context "new" do
    it "accepts strings" do
      expect { Crypto::Boxer.new(alicepk, bobsk) }.to_not raise_error(Exception)
    end

    it "accepts KeyPairs" do
      expect { Crypto::Boxer.new(alice_key, bob_key) }.to_not raise_error(Exception)
    end

    it "raises on a nil public key" do
      expect { Crypto::Boxer.new(nil, bobsk) }.to raise_error(ArgumentError, /Must provide a valid public key/)
    end

    it "raises on an invalid public key" do
      expect { Crypto::Boxer.new("hello", bobsk) }.to raise_error(ArgumentError, /Must provide a valid public key/)
    end

    it "raises on a nil secret key" do
      expect { Crypto::Boxer.new(alicepk, nil) }.to raise_error(ArgumentError, /Must provide a valid secret key/)
    end

    it "raises on an invalid secret key" do
      expect { Crypto::Boxer.new(alicepk, "hello") }.to raise_error(ArgumentError, /Must provide a valid secret key/)
    end
  end


  let(:boxer) { Crypto::Boxer.new(alicepk, bobsk) }
  let(:nonce) { "iin\xE9U\xB6+s\xCDb\xBD\xA8u\xFCs\xD6\x82\x19\xE0\x03kz\v7" } # from nacl distribution
  let(:invalid_nonce) { nonce[0,12]  } # too short!
  let(:invalid_nonce2) { nonce + nonce  } # too long!
  let(:message) { # from nacl distribution
    [0xbe,0x07,0x5f,0xc5,0x3c,0x81,0xf2,0xd5,0xcf,0x14,0x13,0x16,0xeb,0xeb,0x0c,0x7b,
      0x52,0x28,0xc5,0x2a,0x4c,0x62,0xcb,0xd4,0x4b,0x66,0x84,0x9b,0x64,0x24,0x4f,0xfc,
      0xe5,0xec,0xba,0xaf,0x33,0xbd,0x75,0x1a,0x1a,0xc7,0x28,0xd4,0x5e,0x6c,0x61,0x29,
      0x6c,0xdc,0x3c,0x01,0x23,0x35,0x61,0xf4,0x1d,0xb6,0x6c,0xce,0x31,0x4a,0xdb,0x31,
      0x0e,0x3b,0xe8,0x25,0x0c,0x46,0xf0,0x6d,0xce,0xea,0x3a,0x7f,0xa1,0x34,0x80,0x57,
      0xe2,0xf6,0x55,0x6a,0xd6,0xb1,0x31,0x8a,0x02,0x4a,0x83,0x8f,0x21,0xaf,0x1f,0xde,
      0x04,0x89,0x77,0xeb,0x48,0xf5,0x9f,0xfd,0x49,0x24,0xca,0x1c,0x60,0x90,0x2e,0x52,
      0xf0,0xa0,0x89,0xbc,0x76,0x89,0x70,0x40,0xe0,0x82,0xf9,0x37,0x76,0x38,0x48,0x64,
      0x5e,0x07,0x05].pack('c*')
  }
  let(:ciphertext) { # from nacl distribution
    [0xf3,0xff,0xc7,0x70,0x3f,0x94,0x00,0xe5,0x2a,0x7d,0xfb,0x4b,0x3d,0x33,0x05,0xd9,
      0x8e,0x99,0x3b,0x9f,0x48,0x68,0x12,0x73,0xc2,0x96,0x50,0xba,0x32,0xfc,0x76,0xce,
      0x48,0x33,0x2e,0xa7,0x16,0x4d,0x96,0xa4,0x47,0x6f,0xb8,0xc5,0x31,0xa1,0x18,0x6a,
      0xc0,0xdf,0xc1,0x7c,0x98,0xdc,0xe8,0x7b,0x4d,0xa7,0xf0,0x11,0xec,0x48,0xc9,0x72,
      0x71,0xd2,0xc2,0x0f,0x9b,0x92,0x8f,0xe2,0x27,0x0d,0x6f,0xb8,0x63,0xd5,0x17,0x38,
      0xb4,0x8e,0xee,0xe3,0x14,0xa7,0xcc,0x8a,0xb9,0x32,0x16,0x45,0x48,0xe5,0x26,0xae,
      0x90,0x22,0x43,0x68,0x51,0x7a,0xcf,0xea,0xbd,0x6b,0xb3,0x73,0x2b,0xc0,0xe9,0xda,
      0x99,0x83,0x2b,0x61,0xca,0x01,0xb6,0xde,0x56,0x24,0x4a,0x9e,0x88,0xd5,0xf9,0xb3,
      0x79,0x73,0xf6,0x22,0xa4,0x3d,0x14,0xa6,0x59,0x9b,0x1f,0x65,0x4c,0xb4,0x5a,0x74,
      0xe3,0x55,0xa5].pack('c*')
  }

  let(:corrupt_ciphertext) { ciphertext[80] = " " } # picked at random by fair diceroll
  context "box" do

    it "encrypts a message" do
      boxer.box(nonce, message).should eq ciphertext
    end

    it "raises on a a short nonce" do
      expect { boxer.box(invalid_nonce, message) }.to raise_error(ArgumentError, /Nonce must be #{Crypto::Boxer::NONCE_LEN} bytes long./)
    end

    it "raises on a a long nonce" do
      expect { boxer.box(invalid_nonce, message) }.to raise_error(ArgumentError, /Nonce must be #{Crypto::Boxer::NONCE_LEN} bytes long./)
    end
  end

  context "unbox" do

    it "decrypts a message" do
      boxer.unbox(nonce, ciphertext).should eq message
    end

    it "raises on a truncated message to decrypt" do
      expect { boxer.unbox(nonce, ciphertext[0, 64]) }.to raise_error(Crypto::CryptoError, /Decryption failed. Ciphertext failed verification./)
    end

    it "raises on a corrupt ciphertext" do
      expect { boxer.unbox(nonce, corrupt_ciphertext) }.to raise_error(Crypto::CryptoError, /Decryption failed. Ciphertext failed verification./)
    end

    it "raises on a a short nonce" do
      expect { boxer.box(invalid_nonce, message) }.to raise_error(ArgumentError, /Nonce must be #{Crypto::Boxer::NONCE_LEN} bytes long./)
    end

    it "raises on a a long nonce" do
      expect { boxer.box(invalid_nonce, message) }.to raise_error(ArgumentError, /Nonce must be #{Crypto::Boxer::NONCE_LEN} bytes long./)
    end
  end
end
