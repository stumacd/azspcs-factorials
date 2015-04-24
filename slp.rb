# 19 search quit at:
# [[225629712, 1625, 576], [936000, 129962714112]]]

require "rubygems"
require "./slp_lib"
require "./slp_az"

# Settings
$debug          = false
$find_all_solns = false
$use_caches     = true

# Init
$candidates = []
$best = Set[]
$start = {}
$dist = {}
$factors_cache = {}
$alloptcache = {}

# Vars
$solnsfound = 0
$best_size = 25
$count = 0

# Parameters
$n = (ARGV[0]).to_i
# Using cache 8 - 14 sec, 9 4- mins, 10 - ???
$bot = 9

# Timing

# Load caches
$stderr.print "Loading caches..."
$start = YAML::load( File.read("start-#{$bot}.yml") )
$dist = YAML::load( File.read("dist-#{$bot}.yml") )
#$alloptcache = YAML::load( File.read("alloptcache-#{$bot}.yml") )
$stderr.puts "Caches loaded."


def evaluate(seq)
              # Size of goal   seq       goal_num
  best_case_left = 0
  nums_left = $goal[$n] - seq[1].size
  #puts nums_left
  # Check each number 
  pool = seq[0]
  pool.each do |num|
    d = $dist[num] || ($bot + 1)
    #puts num.to_s + " : " + d.to_s
    best_case_left = d if d > best_case_left
    #puts $start[num].to_s if d < ($bot + 2)
  end
  best_case_left = ($bot + 1) if best_case_left > nums_left
  return best_case_left
end

def add_to_candidates(array)
  #puts "Incoming: #{array.to_s}" 
  num_added = 0
  pool = array[0].uniq.sort.reverse - [0,1,2]
  chain = (array[1].uniq - [0,1,2]) - pool

  # Size check
  # Approximating that each member of the pool will be one step minimum.
  return 0 if (chain.size + evaluate([pool,chain])) > $goal[$n]

  # Modcheck
  pool.each do |me|
    return 0 if $target % me != 0
  end
  # Addition check
  pool.each do |me|
    (pool - [me]).combination(2).each do |combo|
      if (combo[0] + combo[1] == me)
        num_added += add_to_candidates([pool-[me],chain+[me]])
        num_added += add_to_candidates([pool-[combo[0]],chain+[combo[0]]])
        num_added += add_to_candidates([pool-[combo[1]],chain+[combo[1]]])
        return num_added
      end
    end
  end

  # Add simpler combos
  # [288, 273] => [288, 15] + 273

  # pool.each do |me|
  #   (pool - [me]).each do |other|
  #     diff = (me - other).abs
  #     #puts diff.to_s + ": " + $dist[diff].to_s
  #     #puts other.to_s + ": " + $dist[other].to_s
  #     if (me.gcd(other) >= me.gcd(diff)) && (diff < other) && chain.empty?
  #       #puts "Other=>diff : " + other.to_s + "=>" + diff.to_s 
  #       num_added += add_to_candidates([pool + [diff] - [other],chain + [other]])
  #     else
  #       if ($dist[diff] || ($bot + 1) ) < ($dist[other] || ($bot + 1) ) 
  #         num_added += add_to_candidates([pool + [diff] - [other],chain + [other]])
  #       end
  #     end
  #   end
    
  # end

  $candidates << [pool, chain]
  num_added += 1
  return num_added
end

$stderr.puts "Done."


def is_best?(array)
  puts "In best #{array}"
  array = array + [$target]
  
  if array.size <= $goal[$n] + 1
    puts "----"
    if valid?(array)
      puts "****" + array.to_s
      if !$best.include?(array.sort)
        $stderr.puts "****" + array.to_s + "****"
        $output.puts array.to_s
        $best << array.sort
        $solnsfound += 1
      end
      exit unless $find_all_solns
      
    end
  end
end

def keep_factoring?(seq)

  pool = seq[0]
  return true if $start[pool.max].nil?

  # Do a decent search

  best_slp = ($bot + 1)
  nums_left = $goal[$n] - seq[1].size
  

  pool.select{|z| !$start[z].nil? && z == pool.max }.each {|num| 
    best,up_chain = go_up(num,pool-[num],nums_left)
    if best == true
      puts "This happened... #{num} #{pool} #{seq}"
      return true
    end
    is_best?(up_chain + seq[1].reverse) if best != false
  }
  return false
end

def how_near(array,num)
  return 0 if array.empty?
  min_dist = 1000
  return min_dist

end


def getbestrank(others,pool,chain)

  # Looking for small distance between two nums - smaller better
  # Looking for one to divide the other - smaller result better
  # Produce factors that are other numbers in the pool (or close to them +1 num)
  # Looking for high gcd - allows the two resulting nums to be quite small - bonus points if gcf reachable.

  x,y = pool

  # Both already in pool
  if (others + [2]).include?(x) && (others + [2]).include?(y)
    puts "Both already there"
    add_to_candidates([others,chain])
    return
  end

  # Square  
  if x == y
    puts "Square"
    add_to_candidates([others + [x],chain])
    return
  end

  # One already in pool
  if (others + [2]).include?(x)
    puts "x in pool"
    # TODO closeness
    add_to_candidates([others + [y],chain])
    return
  end

  if (others + [2]).include?(y)
    puts "#{y}: y in pool"
    # TODO closeness
    add_to_candidates([others + [x],chain])
    return
  end

  # One divides the other
  if y % x == 0
    #puts "One divides the other"
    add_to_candidates([others + [x] + [y/x],chain+[y]])
    return
  end  

  # if near sweet spots sqrt cubroot etc. TODO
  if ((x-y).abs / y.to_f) < 0.10
    add_to_candidates([others + [x] + [y],chain])
    d = (x-y).abs
    add_to_candidates([others + [x] + [d],chain + [y]])
    add_to_candidates([others + [y] + [d],chain + [x]])
  end

  if ((x-y**0.5).abs / (y**0.5).to_f) < 0.12
    add_to_candidates([others + [x] + [y],chain])
  end

  if ((x-y**0.25).abs / (y**0.25).to_f) < 0.15
    add_to_candidates([others + [x] + [y],chain])
  end

  if ((x-y**0.125).abs / (y**0.125).to_f) < 0.18
    add_to_candidates([others + [x] + [y],chain])
  end

  if ((x-y**0.0625).abs / (y**0.0625).to_f) < 0.2
    add_to_candidates([others + [x] + [y],chain])
  end

  # if near seq :)
  others.each do |must|
    if (x % (x - must).abs) == 0
      puts "Near another x"
      add_to_candidates([others + [x] + [y],chain])
    elsif (y % (y - must).abs) == 0
      puts "Near another y"
      add_to_candidates([others + [x] + [y],chain])
    end
  end


  if others.empty? && x.gcd(y) > 10000
    gcd = x.gcd(y)
    add_to_candidates([others + [x/gcd] + [y/gcd] + [gcd],chain + [x] + [y]])
    add_to_candidates([others + [x/(gcd/2)] + [y/(gcd/2)] + [gcd/2],chain + [x] + [y]]) if (gcd % 2) == 0
    add_to_candidates([others + [x/(gcd/3)] + [y/(gcd/3)] + [gcd/3],chain + [x] + [y]]) if (gcd % 3) == 0
    add_to_candidates([others + [x/(gcd/4)] + [y/(gcd/4)] + [gcd/4],chain + [x] + [y]]) if (gcd % 4) == 0
    add_to_candidates([others + [x/(gcd/5)] + [y/(gcd/5)] + [gcd/5],chain + [x] + [y]]) if (gcd % 5) == 0
    add_to_candidates([others + [x/(gcd/6)] + [y/(gcd/6)] + [gcd/6],chain + [x] + [y]]) if (gcd % 6) == 0
    add_to_candidates([others + [x/(gcd/8)] + [y/(gcd/8)] + [gcd/8],chain + [x] + [y]]) if (gcd % 8) == 0
  end

  if others.empty? && x.gcd(y) > 1
    gcd = x.gcd(y)
    add_to_candidates([others + [x/gcd] + [y/gcd] + [gcd],chain + [x] + [y]])
  end

  # High gcf
  if !others.empty? && ([y] + others).all?{|t| t % x == 0}
    puts "One GCD"
    puts others.to_s
    add_to_candidates([others.map{|z| z/x} + [x],chain + others])
    return
  end

  return
end

def smart_factor(seq)
  # Can assume at least one number is not complete
  puts "Smart factoring"
  pool, chain = seq
  #puts "Max dist: " + max_dist.to_s

  a = pool.sort.reverse.max
  puts "Top Dog: " + a.to_s
  
  #cand = []

  (a.factors_sqrt-[1]).sort.reverse.each {|factor|

    #puts "D Factor: " + factor.inspect
    
    #N.B. Y always greatest
    x = factor
    y = a/factor
    z = (x-y).abs

    #next if $target % z != 0 && chain.size == 1
    #next if x % z != 0 && y % z != 0 && chain.size == 1

    #$stderr.puts "x: #{x} - y: #{y} - z: #{z}"

    getbestrank(pool-[a],[x,y],chain + [a])
    next if x == y
    getbestrank(pool-[a],[z,x],chain + [a] + [y]) if z < y
    getbestrank(pool-[a],[z,y],chain + [a] + [x]) if z < x
  }  
  puts "Candidates: #{$candidates.size}"
  $candidates.each{|z| puts z.to_s}

  #cand[0..100].each{|z| puts z.to_s}
end


# Test 20
#$candidates = [[[78848, 1755, 45], [78975]]]

#$candidates = []
#add_to_candidates([[56160,110880],[]])



$stderr.print "Factoring Goal..."
$target = $n.factorial_iterative
smart_factor([[$target],[]])

$stderr.puts "Done."
$big = 100000000000000000000000000


def eval(pool)
  return pool.size*$big + pool.sum
end

$highlist = $candidates.uniq.sort{|x,y| eval(x[0]) <=> eval(y[0])}

$highlist.each_with_index do |z,i|
  $highlist[i][1] = z[1] - [$target]
end


#exit
#$highlist = [[[79968, 54486432, 617760], [8841761993739701954543616000000, 2973891697920000, 2973128443084800, 763254835200, 1235520, 54566400]]]

puts "Test----"
$highlist[0..100].each do |z|
  puts z.to_s
  puts eval(z[0])
end
# Temp
#l = $highlist.index([[12926008369442488320000], []])
$highlist = $highlist.drop(1)
$output = File.new("temp.txt", "w")
while !$highlist.empty?

  $candidates = $highlist.shift(1)

  $stderr.puts "Taking: " + $candidates.to_s

  i = 0
  while !$candidates.empty?
    i += 1
    $stderr.puts "Round #{i}: #{$candidates.size}"
    # TODO temp
    break if i > 3
    temp = $candidates
    $candidates = []
    temp.each do |seq|
      puts "-- " + seq.to_s
      if keep_factoring?(seq)
        puts "Keep factoring."
        smart_factor(seq)
      end
    end
    puts "Candidates:"
    $candidates.each{|z| puts z.to_s}
  end
  #exit
end

$stderr.puts "Loops: " + $count.to_s
$stderr.puts "Solutions found: " + $solnsfound.to_s
# Save any values

# Present results
