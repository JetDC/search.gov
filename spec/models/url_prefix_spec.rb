require 'spec/spec_helper'

describe UrlPrefix do
  fixtures :document_collections, :url_prefixes

  before do
    @valid_attributes = {
      :prefix => 'http://www.foo.gov/folder',
      :document_collection => document_collections(:sample)
    }
  end

  describe "Creating new instance" do
    it { should belong_to :document_collection }
    it { should validate_presence_of :prefix }
    it { should validate_uniqueness_of(:prefix).scoped_to(:document_collection_id) }
    it { should_not allow_value("foogov").for(:prefix)}
    it { should allow_value("http://www.foo.gov/").for(:prefix)}
    it { should allow_value("http://foo.gov/subfolder/").for(:prefix)}

    it "should cap prefix length at 100 characters" do
      too_long = "http://www.foo.gov/#{'waytoolong'*10}/"
      url_prefix = UrlPrefix.new(@valid_attributes.merge(:prefix=> too_long))
      url_prefix.should_not be_valid
      url_prefix.errors[:prefix].first.should =~ /too long/
    end

    it "should validate the URL prefix against URI.parse" do
      url_prefix = UrlPrefix.new(@valid_attributes.merge(:prefix => "http://www.gov.gov/pipesare||bad/"))
      url_prefix.valid?.should be_false
      url_prefix.errors.full_messages.first.should == "URL prefix format is not recognized"
    end

    context "when submitted URL prefix is missing the protocol" do
      it "should prepend it before validation" do
        UrlPrefix.create!(@valid_attributes.merge(:prefix=> "www.foo.gov/")).prefix.should == "http://www.foo.gov/"
      end
    end

    context "when submitted URL prefix is missing the trailing slash" do
      it "should append it before validation" do
        UrlPrefix.create!(@valid_attributes.merge(:prefix=> "http://www.foo.gov")).prefix.should == "http://www.foo.gov/"
      end
    end
  end

  describe "#label" do
    it "should return the prefix" do
      UrlPrefix.new(:prefix => "foo").label.should == "foo"
    end
  end
end