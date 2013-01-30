# coding: utf-8
require 'bundler/setup'
require 'exiv2'
require 'fileutils'

describe Exiv2::XmpData do
  let(:image) do
    image = Exiv2::ImageFactory.open("spec/files/test.jpg")
    image.read_metadata
    image
  end

  let(:xmp_data) { image.xmp_data }

  it "should read XMP data" do
    xmp_data.should be_a(Exiv2::XmpData)
    xmp_data.inspect.should == '#<Exiv2::XmpData: {"Xmp.dc.description"=>{"x-default"=>"This is a description"}, "Xmp.dc.title"=>{"x-default"=>"Pickled"}}>'
    xmp_data.to_a.should == [
      ["Xmp.dc.title", {"x-default"=>"Pickled"}],
      ["Xmp.dc.description", {"x-default"=>"This is a description"}]
    ]
  end

  it "should convert xmp data into a hash" do
    xmp_hash = xmp_data.to_hash
    xmp_hash.should be_a(Hash)
    xmp_hash.should == {
      "Xmp.dc.title"       => {"x-default"=>"Pickled"},
      "Xmp.dc.description" => {"x-default"=>"This is a description"}
    }
  end

  it "should write XMP data" do
    xmp_data["Xmp.dc.title"] = "lang=\"x-default\" Changed!"
    xmp_data.to_hash["Xmp.dc.title"].should == {"x-default"=>"Changed!"}
  end

  it "should set XMP data" do
    xmp_data["Xmp.dc.title"] = "A New Title"
    xmp_data.to_hash["Xmp.dc.title"].should == {"x-default"=>"A New Title"}
  end

  it "should set multiply XMP alt values" do
    xmp_data["Xmp.dc.title"] = ["abc", "lang=\"ab-CE\" cde"]
    xmp_data.to_hash["Xmp.dc.title"].should == {"x-default"=>"abc", "ab-CE"=>"cde"}
  end

  it "should set multiple values for XMP subject" do
    xmp_data["Xmp.dc.subject"] = ["kw1", "kw2"]
    xmp_data.to_hash["Xmp.dc.subject"].should == ["kw1", "kw2"]
  end

  it "should delete all values of XMP data" do
    xmp_data.delete_all("Xmp.dc.title")
    xmp_data.to_hash["Xmp.dc.title"].should == nil
  end

  it "should support array operations on XmpBag types" do
    xmp_data["Xmp.dc.subject"] += [ "aaaa" ]
    xmp_data["Xmp.dc.subject"] += [ "bbbb", "cccc" ]
    xmp_data["Xmp.dc.subject"] -= [ "cccc" ]

    xmp_data["Xmp.dc.subject"].should =~ ["aaaa", "bbbb"]
  end
end
