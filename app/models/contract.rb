class Contract < ActiveRecord::Base
  
  # Attributes:
  # integer: player_id
  # integer: seller_id
  # integer: team_id
  # float: transfer_amount
  # float: wage
  # integer: type (loan, fulltime)
  # date: start_date
  # date: end_date
  
  belongs_to :player
  belongs_to :team
  belongs_to :seller, class_name: "Team"
  
end
