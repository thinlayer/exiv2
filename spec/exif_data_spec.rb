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

describe Exiv2::ExifData do
  let(:image) do
    image = Exiv2::ImageFactory.open("spec/files/test.jpg")
    image.read_metadata
    image
  end

  let(:exif_data) { image.exif_data }

  it "should return rationals" do
    exif_data["Exif.GPSInfo.GPSLatitude"][0].should be_a(Rational)
  end

  it "should read Exif data" do
    exif_data.should be_a(Exiv2::ExifData)
    exif_data.to_a.should == [
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
    exif_hash = exif_data.to_hash
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
    exif_data.add("Exif.Image.Software", "ruby-exiv2")
    exif_data.to_hash.should == {
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
    exif_data["Exif.Image.Software"] = "ruby-exiv2"
    exif_data.to_hash["Exif.Image.Software"].should == "ruby-exiv2"
  end

  it "should set multiply Exif data values" do
    exif_data["Exif.Image.Software"] = ["ruby-exiv2", "plasq skitch"]
    exif_data.to_hash["Exif.Image.Software"].should == ["ruby-exiv2", "plasq skitch"]
  end

  it "should delete one value of Exif data" do
    exif_data["Exif.Image.Software"] = ["ruby-exiv2", "plasq skitch"]
    exif_data.delete("Exif.Image.Software")
    exif_data.to_hash["Exif.Image.Software"].should == "plasq skitch"
  end

  it "should delete all values of Exif data" do
    exif_data.delete_all("Exif.Image.Software")
    exif_data.to_hash["Exif.Image.Software"].should == nil
  end
end
