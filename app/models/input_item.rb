# Join table to connect Bundle/Paper and Inputs
class InputItem < ApplicationRecord
  include Turbo::Broadcastable

  belongs_to :input
  belongs_to :bundle, optional: true
  belongs_to :paper, optional: true
  belongs_to :user, optional: true
  has_one_attached :image # only for input type Image (User uploaded image)
  has_one_attached :generated_image # AI-generated image result

  # Virtual attribute to reuse an existing blob
  attr_accessor :blob_id

  before_validation :attach_blob_if_present

  # Scope for distinct images by checksum (no duplicates)
  scope :distinct_images_for, ->(papers) {
    latest_ids = where(paper: papers)
      .joins(:input)
      .joins(image_attachment: :blob)
      .where(inputs: { type: "Input::Image" })
      .group("active_storage_blobs.checksum")
      .select("MAX(input_items.id) as id")
      .map(&:id)

    where(id: latest_ids)
      .includes(image_attachment: :blob)
      .order(created_at: :desc)
  }

  # Example : For Marvel, user can have to specify "Spiderman in purple"
  # In order to do that we need to let user input a prompt (stored in input_items) + input.promt which is the app's default prompt
  def prompt
    [ input.prompt, super ].compact_blank.join(". ")
  end

  private

  def attach_blob_if_present
    return if blob_id.blank?
    return if image.attached? # Don't override if file was uploaded

    blob = ActiveStorage::Blob.find_by(id: blob_id)
    image.attach(blob) if blob
  end
end
