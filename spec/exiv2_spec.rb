# coding: utf-8
require 'bundler/setup'
require 'exiv2'
require 'fileutils'

describe Exiv2 do
  it "should handle a Pathname being passed to open" do
    image = Exiv2::ImageFactory.open(Pathname.new("spec/files/test.jpg").to_s)
    image.read_metadata
    image.iptc_data.to_hash.should_not be_empty
  end

  it "should raise an error when trying to open a non-existant file" do
    expect {
      Exiv2::ImageFactory.open("tmp/no-such-file.jpg")
    }.should raise_error(Exiv2::BasicError)
  end

  it "should write metadata" do
    FileUtils.cp("spec/files/test.jpg", "spec/files/test_tmp.jpg")
    image = Exiv2::ImageFactory.open("spec/files/test_tmp.jpg")
    image.read_metadata
    image.iptc_data["Iptc.Application2.Caption"] = "A New Caption"
    image.write_metadata
    image = nil

    image2 = Exiv2::ImageFactory.open("spec/files/test_tmp.jpg")
    image2.read_metadata
    image2.iptc_data["Iptc.Application2.Caption"].should == "A New Caption"
    FileUtils.rm("spec/files/test_tmp.jpg")
  end

  it 'reads UTF-8 data' do
    image = Exiv2::ImageFactory.open(Pathname.new("spec/files/photo_with_utf8_description.jpg").to_s)
    image.read_metadata
    description = image.exif_data["Exif.Image.ImageDescription"]
    if description.respond_to? :encoding # Only in Ruby 1.9+
      description.encoding.should == Encoding::UTF_8
    end
    description.should == 'UTF-8 description. ☃ł㌎'
  end

  it 'reads UTF-8 data in each' do
    if String.new.respond_to? :encoding # Only in Ruby 1.9+
      image = Exiv2::ImageFactory.open(Pathname.new("spec/files/photo_with_utf8_description.jpg").to_s)
      image.read_metadata
      image.exif_data.each do |key,value|
        key.encoding.should   == Encoding::UTF_8
        value.encoding.should == Encoding::UTF_8 if value.is_a?(String)
      end
    end
  end
end

