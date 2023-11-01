require 'test_helper'

class ThumbnailCreatorTest < ActiveSupport::TestCase
  FORMATS = %w[jpg png]

  setup do
    @thumbnails = {}
    @thumbnail_creators = {}
    FORMATS.each do |format|
      @thumbnails[format] = thumbnails(format.to_sym)
      @thumbnail_creators[format] = ThumbnailCreator.new(@thumbnails[format])
    end
  end

  FORMATS.each do |format|
    define_method("test_should_process_thumbnail_without_errors_for_#{format}") do
      assert_nothing_raised do
        @thumbnail_creators[format].process
      end
    end

    define_method("test_should_attach_thumbnail_image_after_processing_for_#{format}") do
      assert_not @thumbnails[format].thumbnail_image.attached?
      @thumbnail_creators[format].process
      assert @thumbnails[format].thumbnail_image.attached?
    end

    define_method("test_attached_thumbnail_image_should_have_expected_dimensions_for_#{format}") do
      assert_not @thumbnails[format].thumbnail_image.attached?
      @thumbnail_creators[format].process
      thumbnail_image = @thumbnails[format].thumbnail_image.blob
      thumbnail_image.analyze unless thumbnail_image.analyzed?
      assert_equal 1280, thumbnail_image.metadata['width']
      assert_equal 720, thumbnail_image.metadata['height']
    end
  end
end
