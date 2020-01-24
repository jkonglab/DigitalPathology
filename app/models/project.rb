class Project < ActiveRecord::Base
  has_many :images
  has_many :user_project_ownerships
  has_many :users, :through => :user_project_ownerships
  accepts_nested_attributes_for :user_project_ownerships, allow_destroy: true
  enum visibility: { hidden: 0, visible: 1 }

  before_destroy :destroy_children

  def destroy_children
    self.user_project_ownerships.destroy_all
    self.images.destroy_all
  end

  DIMENSION_TYPES = ['2D', '3D', '4D']
  LOCATION_TYPES = ['Brain', 'Breast', 'Colon', 'Head', 'Kidney', 'Liver', 'Lung', 'Ovary', 'Pancreas', 'Prostate', 'Skin', 'Stomach', 'Thyroid', 'Uterus', 'Other']
  MODALITY_TYPES = ['CT', 'CR', 'Fluorescent', 'H&E', 'IHC', 'MRI', 'PET', 'Ultrasound' ]

end