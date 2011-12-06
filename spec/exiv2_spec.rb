# coding: utf-8
require 'bundler/setup'
require 'exiv2'
require 'fileutils'
require 'rational'

def rational(a, b)
  # 1.8
  return Rational.new!(a, b) if Rational.respond_to? :"new!"
  # 1.9+
  return Rational(a, b) if Rational.respond_to? :Rational
  # fallback
  return a / Float(b)
end


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
        value.encoding.should == Encoding::UTF_8
      end
    end
  end
  
  let(:image) do
    image = Exiv2::ImageFactory.open("spec/files/test.jpg")
    image.read_metadata
    image
  end

  context "IPTC data" do
    before do
      @iptc_data = image.iptc_data
    end

    it "should return IPTC time values as ruby time objects" do
      @iptc_data['Iptc.Application2.ReleaseDate'].should be_kind_of(Time)
      @iptc_data['Iptc.Application2.ReleaseTime'].should be_kind_of(Time)
    end
    
    it "should read IPTC data" do
      @iptc_data.should be_a(Exiv2::IptcData)
      @iptc_data.to_a.should == [
        ["Iptc.Application2.Caption", "Rhubarb rhubarb rhubard"],
        ["Iptc.Application2.Keywords", "fish"],
        ["Iptc.Application2.Keywords", "custard"],
        ["Iptc.Application2.ReleaseDate", Time.utc(2412, 12, 6)],
        ["Iptc.Application2.ReleaseTime", Time.utc(1970, 1, 1, 11, 11, 11)],
      ]
    end

    it "should convert iptc data into a hash" do
      iptc_hash = @iptc_data.to_hash
      iptc_hash.should be_a(Hash)
      iptc_hash.should == {
        "Iptc.Application2.Caption"  => "Rhubarb rhubarb rhubard",
        "Iptc.Application2.Keywords" => ["fish", "custard"],
        "Iptc.Application2.ReleaseDate" => Time.utc(2412, 12, 6),
        "Iptc.Application2.ReleaseTime" => Time.utc(1970, 1, 1, 11, 11, 11),
      }
    end
    
    it "should write IPTC data" do
      @iptc_data.add("Iptc.Application2.Keywords", "fishy")
      @iptc_data.to_a.should == [
        ["Iptc.Application2.Caption", "Rhubarb rhubarb rhubard"],
        ["Iptc.Application2.Keywords", "fish"],
        ["Iptc.Application2.Keywords", "custard"],
        ["Iptc.Application2.ReleaseDate", Time.utc(2412, 12, 6)],
        ["Iptc.Application2.ReleaseTime", Time.utc(1970, 1, 1, 11, 11, 11)],
        ["Iptc.Application2.Keywords", "fishy"],
      ]
    end
    
    it "should set IPTC data" do
      @iptc_data["Iptc.Application2.Caption"] = "A New Caption"
      @iptc_data.to_hash["Iptc.Application2.Caption"].should == "A New Caption"
    end
    
    it "should set multiply IPTC data values" do
      @iptc_data["Iptc.Application2.Keywords"] = ["abc", "cde"]
      @iptc_data.to_hash["Iptc.Application2.Keywords"].should == ["abc", "cde"]
    end
    
    it "should delete one value of IPTC data" do
      @iptc_data.delete("Iptc.Application2.Keywords")
      @iptc_data.to_hash["Iptc.Application2.Keywords"].should == "custard"
    end
    
    it "should delete all values of IPTC data" do
      @iptc_data.delete_all("Iptc.Application2.Keywords")
      @iptc_data.to_hash["Iptc.Application2.Keywords"].should == nil
    end
  end

  context "XMP data" do
    before do
      @xmp_data = image.xmp_data
    end

    it "should read XMP data" do
      @xmp_data.should be_a(Exiv2::XmpData)
      @xmp_data.inspect.should == '#<Exiv2::XmpData: {"Xmp.dc.description"=>"lang=\"x-default\" This is a description", "Xmp.dc.title"=>"lang=\"x-default\" Pickled"}>'
      @xmp_data.to_a.should == [
        ["Xmp.dc.title", "lang=\"x-default\" Pickled"],
        ["Xmp.dc.description", "lang=\"x-default\" This is a description"]
      ]
    end

    it "should convert xmp data into a hash" do
      xmp_hash = @xmp_data.to_hash
      xmp_hash.should be_a(Hash)
      xmp_hash.should == {
        "Xmp.dc.title"       => "lang=\"x-default\" Pickled",
        "Xmp.dc.description" => "lang=\"x-default\" This is a description"
      }
    end

    it "should write XMP data" do
      @xmp_data["Xmp.dc.title"] = "lang=\"x-default\" Changed!"
      @xmp_data.to_hash["Xmp.dc.title"].should == "lang=\"x-default\" Changed!"
    end
    
    it "should set XMP data" do
      @xmp_data["Xmp.dc.title"] = "A New Title"
      @xmp_data.to_hash["Xmp.dc.title"].should == "lang=\"x-default\" A New Title"
    end
    
    it "should set multiply XMP data values" do
      @xmp_data["Xmp.dc.title"] = ["abc", "cde"]
      @xmp_data.to_hash["Xmp.dc.title"].should == ["lang=\"x-default\" abc", "lang=\"x-default\" cde"]
    end
    
    it "should delete one value of XMP data" do
      @xmp_data["Xmp.dc.title"] = ["abc", "cde"]
      @xmp_data.delete("Xmp.dc.title")
      @xmp_data.to_hash["Xmp.dc.title"].should == "lang=\"x-default\" cde"
    end
    
    it "should delete all values of XMP data" do
      @xmp_data.delete_all("Xmp.dc.title")
      @xmp_data.to_hash["Xmp.dc.title"].should == nil
    end
  end

  context "EXIF data" do
    before do
      @exif_data = image.exif_data
    end

    it "should return rationals" do
      @exif_data["Exif.GPSInfo.GPSLatitude"][0].should be_a(Rational)
    end
    
    it "should read Exif data" do
      @exif_data.should be_a(Exiv2::ExifData)
      @exif_data.to_a.should == [
        ["Exif.Image.Software",         "plasq skitch"],
        ["Exif.Image.ExifTag",          62],
        ["Exif.Photo.ExifVersion",      "48 50 49 48"],
        ["Exif.Photo.PixelXDimension",  32],
        ["Exif.Photo.PixelYDimension",  32],
        ["Exif.Image.GPSTag",           104],
        ["Exif.GPSInfo.GPSLatitude",    [rational(4, 1), rational(22, 1), rational(1, 3)]]
      ]
    end

    it "should convert xmp data into a hash" do
      exif_hash = @exif_data.to_hash
      exif_hash.should be_a(Hash)
      exif_hash.should == {
        "Exif.Image.Software"        => "plasq skitch",
        "Exif.Image.ExifTag"         => 62,
        "Exif.Photo.ExifVersion"     => "48 50 49 48",
        "Exif.Photo.PixelXDimension" => 32,
        "Exif.Photo.PixelYDimension" => 32,
        "Exif.Image.GPSTag"          => 104,
        "Exif.GPSInfo.GPSLatitude"   => [rational(4, 1), rational(22, 1), rational(1, 3)]
      }
    end

    it "should write Exif data" do
      @exif_data.add("Exif.Image.Software", "ruby-exiv2")
      @exif_data.to_hash.should == {
        "Exif.Image.Software"        => ["plasq skitch", "ruby-exiv2"],
        "Exif.Image.ExifTag"         => 62,
        "Exif.Photo.ExifVersion"     => "48 50 49 48",
        "Exif.Photo.PixelXDimension" => 32,
        "Exif.Photo.PixelYDimension" => 32,
        "Exif.Image.GPSTag"          => 104,
        "Exif.GPSInfo.GPSLatitude"   => [rational(4, 1), rational(22, 1), rational(1, 3)]
      }
    end
    
    it "should set Exif data" do
      @exif_data["Exif.Image.Software"] = "ruby-exiv2"
      @exif_data.to_hash["Exif.Image.Software"].should == "ruby-exiv2"
    end
    
    it "should set multiply Exif data values" do
      @exif_data["Exif.Image.Software"] = ["ruby-exiv2", "plasq skitch"]
      @exif_data.to_hash["Exif.Image.Software"].should == ["ruby-exiv2", "plasq skitch"]
    end
    
    it "should delete one value of Exif data" do
      @exif_data["Exif.Image.Software"] = ["ruby-exiv2", "plasq skitch"]
      @exif_data.delete("Exif.Image.Software")
      @exif_data.to_hash["Exif.Image.Software"].should == "plasq skitch"
    end
    
    it "should delete all values of Exif data" do
      @exif_data.delete_all("Exif.Image.Software")
      @exif_data.to_hash["Exif.Image.Software"].should == nil
    end
  end
end

