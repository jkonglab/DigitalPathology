class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :user_image_ownerships
  has_many :images, :through => :user_image_ownerships
  has_many :annotations
  has_many :runs
  has_many :results, through: :runs
end
