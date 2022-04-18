# coding: utf-8

require 'spec_helper'

RSpec.describe Apress::Images::Imageable do
  let(:image) { build :subject_image }
  let(:dummy_filepath) { Rails.root.join('../fixtures/images/sample_image.jpg') }

  before { allow(Apress::Images::ProcessJob).to receive(:enqueue) }

  it { expect(image).to have_attached_file(:img) }
  it { expect(image).to validate_attachment_presence(:img) }
  it { expect(image).to validate_attachment_content_type(:img).allowing('image/png', 'image/gif', 'image/webp') }
  it { expect(image).to validate_attachment_content_type(:img).rejecting('text/plain', 'text/xml') }
  it { expect(image).to validate_attachment_size(:img).less_than(image.class.max_size.megabytes) }

  describe '#styles' do
    it { expect(image.styles).to eq image.class.attachment_options[:styles].keys }
  end

  describe 'delegated methods' do
    before { allow_any_instance_of(Paperclip::Attachment).to receive(:path).and_return(dummy_filepath) }

    it 'delegates attachment methods' do
      expect(image.files).to eq(image.img.files)
      expect(image.fingerprints).to eq(image.img.fingerprints)
    end
  end

  describe '#normalize_positions' do
    context 'when save' do
      it { expect(image.class).to receive(:normalize_positions) }

      after { image.save! }
    end

    context 'when destroy' do
      let!(:image) { create :subject_image }

      it { expect(image.class).to receive(:normalize_positions) }

      after { image.destroy }
    end
  end

  context 'when model has custom attachment attribute' do
    let(:image) { build :custom_attribute_image, custom: nil }
    let(:attachment) { Rack::Test::UploadedFile.new(Rails.root.join(dummy_filepath), 'image/jpeg') }

    it 'assigns image by default attribute (img)' do
      expect { image.update_attributes!(img: attachment) }.to change { image.custom_file_name }
    end

    it 'assigns image by custom attribute' do
      expect { image.update_attributes!(custom: attachment) }.to change { image.custom_file_name }
    end
  end
end
