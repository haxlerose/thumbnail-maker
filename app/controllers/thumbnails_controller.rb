# frozen_string_literal: true

class ThumbnailsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_thumbnail, only: [:show, :edit, :update, :destroy]

  def index
    @thumbnails = current_user.thumbnails
  end

  def new
    @thumbnail = current_user.thumbnails.build
  end

  def create
    @thumbnail = current_user.thumbnails.build(thumbnail_params)

    if @thumbnail.save
      @thumbnail.create_thumbnail_image
      redirect_to thumbnails_path, notice: 'Thumbnail was successfully created.'
    else
      render :new
    end
  end

  def show
    @thumbnail = Thumbnail.find(params[:id])
  end

  def edit
  end

  def update
    if @thumbnail.update(thumbnail_params)
      @thumbnail.create_thumbnail_image
      redirect_to @thumbnail, notice: 'Thumbnail was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @thumbnail.destroy
    redirect_to thumbnails_path, notice: 'Thumbnail was successfully deleted.'
  end

  private

  def set_thumbnail
    @thumbnail = Thumbnail.find(params[:id])
  end

  def thumbnail_params
    params.require(:thumbnail).permit(:title, :uploaded_image)
  end
end
