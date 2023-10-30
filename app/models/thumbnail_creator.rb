# frozen_string_literal: true

class ThumbnailCreator
  def initialize(thumbnail)
    @thumbnail = thumbnail
  end

  def process
    tempfile = Tempfile.new(["uploaded_image", ".jpg"])
    tempfile.binmode
    tempfile.write(@thumbnail.uploaded_image.download)
    tempfile.close

    uploaded_image_path = tempfile.path
    puts "Uploaded Image Path: #{uploaded_image_path}}"

    # Resize the uploaded image to have a height of 720 pixels while maintaining its aspect ratio
    resized_image_path = Rails.root.join('tmp', 'temp_resized_image.jpg').to_s
    resized_image = ImageProcessing::Vips
                      .source(uploaded_image_path)
                      .resize_to_fit(nil, 720)
                      .call(destination: resized_image_path)
    puts "Resized Image Path: #{resized_image_path}"
    puts "Resized Image Exists? #{File.exist?(resized_image_path)}"

    resized_image = Vips::Image.new_from_file(resized_image_path)
    puts "Resized Image Dimensions: #{resized_image.width}x#{resized_image.height}"
    # byebug

    # Create a blank canvas of 1280x720
    canvas = Vips::Image.black(1280, 720).invert
    canvas_path = Rails.root.join('tmp', 'temp_canvas.jpg').to_s
    canvas.write_to_file(canvas_path)
    puts "Canvas Dimensions: #{canvas.width}x#{canvas.height} -- path: #{canvas_path}"

    resized_image_width = Vips::Image.new_from_file(resized_image_path).width

    # Calculate the position to start pasting the resized image onto the canvas
    x_offset = 960 - (resized_image_width / 2)
    puts "X Offset: #{x_offset}"
    x_offset = [x_offset, 640].max
    puts "X Offset after max: #{x_offset}"

    # Composite the resized image onto the right half of the canvas
    canvas = ImageProcessing::Vips
               .source(canvas_path)
               .composite(resized_image_path, offset: [x_offset, 0])
               .call
    canvas_path = canvas.path

    # Crop the image if it exceeds the canvas width
    if resized_image_width > 640
      excess_width = resized_image_width - 640
      crop_start = x_offset - (excess_width / 2)
      canvas = ImageProcessing::Vips
                 .source(canvas_path)
                 .crop(crop_start, 0, 1280 - excess_width, 720)
                 .call
      canvas_path = canvas.path
    end

    # TODO: Add the title to the left half of the canvas
    title_text = @thumbnail.title
    title_image = Vips::Image.text(title_text, font: "sans 30", width: 640, align: :centre)

    font_size = if title_text.length <= 10
                  50
                elsif title_text.length <= 20
                  40
                else
                  30
                end

    title_image = Vips::Image.text(title_text, font: "sans #{font_size}", width: 640, align: :centre)
    title_image_path = Rails.root.join('tmp', 'temp_title_image.jpg').to_s
    title_image.write_to_file(title_image_path)

    thumbnail_tempfile = Tempfile.new(["thumbnail_image", ".jpg"])
    thumbnail_tempfile.binmode
    thumbnail_tempfile.write(@thumbnail.thumbnail_image.download)
    thumbnail_tempfile.close

    thumbnail_image_path = thumbnail_tempfile.path
    thumbnail_image = Vips::Image.new_from_file(thumbnail_image_path)

    # composite_image = thumbnail_image.composite([title_image], ['over'])

    title_image = title_image.gravity("centre", 640, 720)
    composite_image = thumbnail_image.composite([title_image], ['over'])

    composite_image_path = Rails.root.join('tmp', 'temp_composite_image.jpg').to_s
    composite_image.write_to_file(composite_image_path)

    @thumbnail.thumbnail_image.attach(io: File.open(composite_image_path), filename: "thumbnail_image.jpg", content_type: "image/jpg")


    # @thumbnail.thumbnail_image.attach(io: File.open(canvas_path), filename: "thumbnail_image.jpg", content_type: "image/jpg")
    File.delete(resized_image_path)
    File.delete(canvas_path)
    tempfile.unlink
    File.delete(composite_image_path)
    thumbnail_tempfile.unlink
  end

  # TODO: Create a method or use an image to generate the title part of the thumbnail
end

