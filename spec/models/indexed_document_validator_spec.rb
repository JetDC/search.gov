require 'spec_helper'

describe IndexedDocumentValidator, "#perform(indexed_document_id)" do
  fixtures :affiliates
  let(:aff) { affiliates(:basic_affiliate) }
  before do
    aff.indexed_documents.destroy_all
    aff.features << Feature.find_or_create_by_internal_name('hosted_sitemaps', :display_name => "hs")
    @idoc = aff.indexed_documents.create!(
      :title => 'PDF Title',
      :description => 'This is a PDF document.',
      :url => 'http://nps.gov/pdf.pdf',
      :last_crawl_status => IndexedDocument::OK_STATUS,
      :body => "this is the doc body",
      :affiliate_id => affiliates(:basic_affiliate).id,
      :content_hash => "a6e450cc50ac3b3b7788b50b3b73e8b0b7c197c8"
    )
  end

  context "when it can locate the IndexedDocument for an affiliate" do
    before do
      IndexedDocument.stub!(:find_by_id).and_return @idoc
    end

    context "when the IndexedDocument is not valid" do
      before do
        @idoc.stub!(:valid?).and_return false
      end

      it "should destroy the IndexedDocument" do
        @idoc.should_receive(:destroy)
        IndexedDocumentValidator.perform(@idoc.id)
      end

      it "should remove IndexedDocument from solr" do
        IndexedDocument.solr_search_ids { with :affiliate_id, aff.id }.should_not be_blank
        @idoc.should_receive(:remove_from_index)
        IndexedDocumentValidator.perform(@idoc.id)
      end
    end

    context "when the IndexedDocument is valid" do
      before do
        @idoc.stub!(:valid?).and_return true
      end

      it "should not delete the IndexedDocument" do
        @idoc.should_not_receive(:delete)
        IndexedDocumentValidator.perform(@idoc.id)
      end
    end
  end
end