# frozen_string_literal: true

class Thumbnail < ApplicationRecord
  belongs_to :user
  has_one_attached :uploaded_image
  has_one_attached :thumbnail_image

  validates :title, presence: true
  validate :uploaded_image_attached

  def create_thumbnail_image
    ThumbnailCreator.new(self).process
  end

  private

  def uploaded_image_attached
    errors.add(:uploaded_image, "must be attached") unless uploaded_image.attached?
  end
end
