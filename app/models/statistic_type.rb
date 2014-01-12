class StatisticType < ActiveRecord::Base
  
  # Attributes
  # string: abbrev
  # string: name
  # text: description
  attr_accessible :abbrev, :name, :description
  
  has_many :statistics
  
end
