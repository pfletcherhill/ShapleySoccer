class Statistic < ActiveRecord::Base
  
  # Associations
  belongs_to :appearance
  belongs_to :statistic_type
  
  # Validations
  validates_uniqueness_of :stat_type, scope: [:appearance_id]
  
  TYPES = [
    "SH", # Shots
    "SG", # Shots on goal
    "G", # Goals
    "A", # Assists
    "OF", # Offsides
    "FD", # Fouls drawn
    "FC", # Fouls committed
    "SV", # Saves
    "YC", # Yellow cards
    "RC" # Red cards
  ]
  
  # Define methods to test for each type
  TYPES.each_with_index do |meth, index|
    define_method("#{meth}?") { type == type }
  end
  
  # Class Methods
  def self.of_type (type, options = {})
    where(stat_type: type)
  end
  
end
