# coding: utf-8
require 'bundler/setup'
require 'exiv2'
require 'fileutils'

describe Exiv2::IptcData do
  let(:image) do
    image = Exiv2::ImageFactory.open("spec/files/test.jpg")
    image.read_metadata
    image
  end

  let(:iptc_data) { image.iptc_data }

  it "should return IPTC time values as ruby time objects" do
    iptc_data['Iptc.Application2.ReleaseDate'].should be_kind_of(Time)
    iptc_data['Iptc.Application2.ReleaseTime'].should be_kind_of(Time)
  end

  it "should read IPTC data" do
    iptc_data.should be_a(Exiv2::IptcData)
    iptc_data.to_a.should == [
      ["Iptc.Application2.Caption", "Rhubarb rhubarb rhubard"],
      ["Iptc.Application2.Keywords", "fish"],
      ["Iptc.Application2.Keywords", "custard"],
      ["Iptc.Application2.ReleaseDate", Time.utc(2412, 12, 6)],
      ["Iptc.Application2.ReleaseTime", Time.utc(1970, 1, 1, 11, 11, 11)],
    ]
  end

  it "should convert iptc data into a hash" do
    iptc_hash = iptc_data.to_hash
    iptc_hash.should be_a(Hash)
    iptc_hash.should == {
      "Iptc.Application2.Caption"  => "Rhubarb rhubarb rhubard",
      "Iptc.Application2.Keywords" => ["fish", "custard"],
      "Iptc.Application2.ReleaseDate" => Time.utc(2412, 12, 6),
      "Iptc.Application2.ReleaseTime" => Time.utc(1970, 1, 1, 11, 11, 11),
    }
  end

  it "should write IPTC data" do
    iptc_data.add("Iptc.Application2.Keywords", "fishy")
    iptc_data.to_a.should == [
      ["Iptc.Application2.Caption", "Rhubarb rhubarb rhubard"],
      ["Iptc.Application2.Keywords", "fish"],
      ["Iptc.Application2.Keywords", "custard"],
      ["Iptc.Application2.ReleaseDate", Time.utc(2412, 12, 6)],
      ["Iptc.Application2.ReleaseTime", Time.utc(1970, 1, 1, 11, 11, 11)],
      ["Iptc.Application2.Keywords", "fishy"],
    ]
  end

  it "should set IPTC data" do
    iptc_data["Iptc.Application2.Caption"] = "A New Caption"
    iptc_data.to_hash["Iptc.Application2.Caption"].should == "A New Caption"
  end

  it "should set multiply IPTC data values" do
    iptc_data["Iptc.Application2.Keywords"] = ["abc", "cde"]
    iptc_data.to_hash["Iptc.Application2.Keywords"].should == ["abc", "cde"]
  end

  it "should delete one value of IPTC data" do
    iptc_data.delete("Iptc.Application2.Keywords")
    iptc_data.to_hash["Iptc.Application2.Keywords"].should == "custard"
  end

  it "should delete all values of IPTC data" do
    iptc_data.delete_all("Iptc.Application2.Keywords")
    iptc_data.to_hash["Iptc.Application2.Keywords"].should == nil
  end
end
