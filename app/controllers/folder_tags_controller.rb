class FolderTagsController < ApplicationController
  before_action :require_admin
  before_action :load_tag, only: %i[edit update destroy]

  def index
    @folder_tags = FolderTag.left_joins(:folder_taggings).group('folder_tags.id').order(:name)
                            .select('folder_tags.*, COUNT(folder_taggings.id) AS folders_count')
  end

  def new
    @folder_tag = FolderTag.new
  end

  def create
    @folder_tag = FolderTag.new(tag_params)
    if @folder_tag.save
      redirect_to folder_tags_path, notice: I18n.t('folder_tags.created')
    else
      render :new
    end
  end

  def edit; end

  def update
    if @folder_tag.update(tag_params)
      redirect_to folder_tags_path, notice: I18n.t('folder_tags.updated')
    else
      render :edit
    end
  end

  def destroy
    @folder_tag.destroy # dependent: :destroy removes its taggings
    redirect_to folder_tags_path, notice: I18n.t('folder_tags.deleted')
  end

  private

  def load_tag
    @folder_tag = FolderTag.find(params[:id])
  end

  def tag_params
    params.require(:folder_tag).permit(:name)
  end
end
