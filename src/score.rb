require "csv"

# source: https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3949410
# supplemental table 4, "2 doses of any vaccine"
def score(from, to) 
  days = (to - from).to_i
  return 0 if days < 15
  return 90 if days <= 30 # 1 month
  return 86 if days <= 60 # 2 months
  return 79 if days <= 120 # 4 months
  return 48.5 if days <= 180 # 6 months
  return 34.5 if days <= 210 # 7 months
  return 2
end

class Group2
  attr_reader :date, :count
  def initialize(date, count)
    @date, @count = date, count
  end

  def score_sum(to)
    @count * score(@date, to) # immunity from 2nd shot
  end
end

class Group3
  attr_reader :date, :count, :prev
  def initialize(date, count, prev)
    @date, @count, @prev = date, count, prev
  end

  def score_sum(to)
    if (to - date).to_i < 15
      @count * score(@prev, to) # immunity from 2nd shot
    else 
      @count * score(@date, to) # immunity from 3rd shot
    end
  end
end

def score_sum(second, third, to)
  sum = 0.0
  second.each do |group|
    sum += group.score_sum(to)
  end
  third.each do |group|
    sum += group.score_sum(to)
  end
  sum
end

def apply_booster(second, third, date, count)
  while (count > 0)
    oldest = second.first
    if count >= oldest.count
      # replace oldest
      second.delete_at(0)
      third << Group3.new(date, oldest.count, oldest.date)
      count -= oldest.count
    else
      # split
      third << Group3.new(date, count, oldest.date)
      second[0] = Group2.new(oldest.date, oldest.count - count)
      count = 0
    end
  end
end

# date source: https://www.rki.de/DE/Content/InfAZ/N/Neuartiges_Coronavirus/Daten/Impfquoten-Tab.html
def parse(second, third)
  CSV.parse(File.read("data/per_day.csv")).each do |row|
    next if row[0] == "Datum" # skip headers
    return if row[0] == "Gesamt" # skip footer

    date = Date.strptime(row[0], "%d.%m.%Y")

    count2 = row[2].gsub(".", "").to_i
    second << Group2.new(date, count2) if count2 > 0

    count3 = row[3].gsub(".", "").to_i
    apply_booster(second, third, date, count3)

    score = score_sum(second, third, date) / 81_100_000.0
    puts "#{date}, #{count2}, #{count3}, #{score.round(1)}"
  end
end

parse([], [])
