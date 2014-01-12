class Statistic < ActiveRecord::Base
  
  # Attributes:
  # integer: apperance_id
  # integer: statistic_type_id
  # float: value
  attr_accessible :appearance_id, :statistic_type_id, :value
  
  belongs_to :appearance
  belongs_to :statistic_type
  
  validates_uniqueness_of :statistic_type, scope: [:appearance_id]
  
end
