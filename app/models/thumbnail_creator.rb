# frozen_string_literal: true

class ThumbnailCreator
  def initialize(thumbnail)
    @thumbnail = thumbnail
  end

  def process
    @thumbnail.thumbnail_image.purge if @thumbnail.thumbnail_image.attached?

    @thumbnail.uploaded_image.analyze unless @thumbnail.uploaded_image.analyzed?

    file_extension = Rack::Mime::MIME_TYPES.invert[@thumbnail.uploaded_image.content_type].delete('.')
    tempfile = Tempfile.new(["uploaded_image_#{SecureRandom.alphanumeric(10)}", ".#{file_extension}"])
    tempfile.binmode
    tempfile.write(@thumbnail.uploaded_image.download)
    tempfile.close
    uploaded_image_path = tempfile.path

    resized_image_path = Rails.root.join('tmp', "temp_resized_image_#{SecureRandom.alphanumeric(10)}.jpg").to_s
    ImageProcessing::Vips.source(uploaded_image_path).resize_to_fit(nil, 720).call(destination: resized_image_path)
    resized_image = Vips::Image.new_from_file(resized_image_path)

    canvas = Vips::Image.black(1280, 720).invert
    canvas_path = Rails.root.join('tmp', "temp_canvas_#{SecureRandom.alphanumeric(10)}.jpg").to_s
    canvas.write_to_file(canvas_path)

    resized_image_width = resized_image.width
    cropped_image = if resized_image_width > 640
                      crop_start = (resized_image_width - 640) / 2
                      resized_image.crop(crop_start, 0, 640, 720)
                    else
                      resized_image
                    end
    x_offset = 960 - (cropped_image.width / 2)
    canvas_with_image = canvas.composite(resized_image, 'over', x: x_offset, y: 0)

    title_text = @thumbnail.title
    font_size = title_font_size(title_text)

    title_image = Vips::Image.text(title_text, font: "sans #{font_size}", width: 640, align: :centre)
    title_image_path = Rails.root.join('tmp', "temp_title_image_#{SecureRandom.alphanumeric(10)}.jpg").to_s
    title_image.write_to_file(title_image_path)

    title_image = title_image.gravity("centre", 640, 720)

    composite_image = canvas_with_image.composite([title_image], ['over'])
    composite_image_path = Rails.root.join('tmp', "temp_composite_image_#{SecureRandom.alphanumeric(10)}.jpg").to_s
    composite_image.write_to_file(composite_image_path)

    @thumbnail.thumbnail_image.attach(io: File.open(composite_image_path), filename: "thumbnail_image_#{SecureRandom.alphanumeric(10)}.jpg", content_type: "image/jpg")

    File.delete(resized_image_path)
    File.delete(canvas_path)
    tempfile.unlink
    File.delete(composite_image_path)
  end

  private

  def title_font_size(title_text)
    if title_text.length <= 10
      50
    elsif title_text.length <= 20
      40
    else
      30
    end
  end
end
