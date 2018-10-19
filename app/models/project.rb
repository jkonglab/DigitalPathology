class Project < ActiveRecord::Base
  has_many :images
  has_many :user_project_ownerships
  has_many :users, :through => :user_project_ownerships
  enum visibility: { hidden: 0, visible: 1 }

  before_destroy :destroy_children

  def destroy_children
    self.user_project_ownerships.destroy_all
    self.images.destroy_all
  end

  MODALITY_TYPES = ['2D', '3D', '4D']
  TISSUE_TYPES = ['Liver', 'Brain', 'Kidney']
  METHOD_TYPES = ['IHC', 'Stain', 'Method2', 'Method3']

end