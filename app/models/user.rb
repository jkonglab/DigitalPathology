class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :user_image_ownerships
  has_many :images, :through => :user_image_ownerships
  has_many :annotations
  has_many :user_run_ownerships
  has_many :runs, :through => :user_run_ownerships
  has_many :results, through: :runs
  
  def self.current
    Thread.current[:user]
  end
  
  def self.current=(user)
    Thread.current[:user] = user
  end
end
