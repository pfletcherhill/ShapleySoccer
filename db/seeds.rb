stat_types = [
  ["SH", "Shots"],
  ["SG", "Shots on Goal"],
  ["G", "Goals"],
  ["A", "Assists"],
  ["OF", "Offsides"],
  ["FD", "Fouls Drawn"],
  ["FC", "Fouls Committed"],
  ["SV", "Saves"],
  ["YC", "Yellow Cards"],
  ["RC", "Red Cards"]
]

stat_types.each do |abbrev, name|
  StatisticType.create(abbrev: abbrev, name: name)
end