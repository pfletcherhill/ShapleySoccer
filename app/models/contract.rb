class Contract < ActiveRecord::Base
    
  belongs_to :player
  belongs_to :team
  belongs_to :seller, class_name: "Team"
  
end
