class UserRunOwnership < ActiveRecord::Base
  belongs_to :user
  belongs_to :run
end
