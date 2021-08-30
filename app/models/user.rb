class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable

  has_many :user_project_ownerships
  has_many :projects, :through => :user_project_ownerships
  has_many :annotations
  has_many :landmarks
  has_many :user_run_ownerships
  has_many :runs, :through => :user_run_ownerships
  has_many :results, through: :runs

  before_destroy :destroy_children


  def destroy_children
    self.user_project_ownerships.destroy_all
    self.user_run_ownerships.destroy_all
    self.annotations.destroy_all
  end

  PERMISSION_LOOKUP={
    "admin" => 10,
    "subadmin" => 9,
    "user" => 0,
  }

  REVERSE_PERMISSION_LOOKUP={
    0 => 'user',
    9 => 'subadmin',
    10 => 'admin'
  }

  def admin?
    self.admin >= PERMISSION_LOOKUP['admin']
  end

  def subadmin?
    self.admin >= PERMISSION_LOOKUP['subadmin']
  end
  
  def self.current
    Thread.current[:user]
  end
  
  def self.current=(user)
    Thread.current[:user] = user
  end

   def active_for_authentication? 
    super && approved? 
  end 
  
  def inactive_message 
    approved? ? super : :not_approved
  end

   after_create :send_admin_mail
  def send_admin_mail
    recepients = ['spaul24@student.gsu.edu', 'paulsapto@gmail.com']
    recepients.each do |recipient|
      AdminMailer.new_user_waiting_for_approval(email, recipient).deliver
    end
  end
end
