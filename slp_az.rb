

$goal = { 6 => 6,
          7 => 7,
          8 => 8,
          9 => 8,
          10 => 9,
          11 => 9,
          12 => 10,
          13 => 11,
          14 => 11,
          15 => 12,
          16 => 12,
          17 => 12,
          18 => 13,
          19 => 13,
          20 => 14,
          # --v 5206m
          21 => 15,
          22 => 14,
          # 15 ---v
          23 => 15,
          # Can't get ---v 1000mins
          24 => 16,
          # Can't get 240 mins
          25 => 17,
          26 => 17,
          # Can't get 950mins
          # 16 --v
          27 => 22,
          # 16 --v
          28 => 21,
          # 17 --v
          29 => 23,
          30 => 17,
          31 => 19,
          # 18
          32 => 26,
          33 => 19,
          34 => 19,
          35 => 19,
          36 => 19,
          37 => 19,
          38 => 21         
        }

$optcache = {}

def useful_factors(a,b)
  return [] if a.gcd(b) == 1
  puts a.gcd(b)
  #puts "Alert" if (a.factors & b.factors) == [1]
  return (a.factors & b.factors).reverse - [1]
end

def cho(a,b)
  return [a-b,b-a,a+b,a*b]
end

def opt(arr)
  return $optcache[arr] unless $optcache[arr].nil?
  list = []
  arr.repeated_combination(2).each do |z|
    list = list + cho(z[0],z[1])
  end
  return $optcache[arr] = list.uniq.select{|x| x > 2}
end

def opt_last(arr)
  list = []
  arr.each do |z|
    list = list + cho(arr[-1],z)
  end
  list.uniq.select{|x| x > 2}
end

# Generate ladders
$combos = [[1,2]]

def generate_ladders(depth)
  $stderr.puts "Generating ladders..."
  2.upto(depth) { |loop|
    $stderr.print loop.to_s + " "
    temp = $combos
    $combos = []
    bignum = $n.factorial_iterative
    temp.each do |x|
      options = opt(x)#.select{|y| bignum % y == 0}
      (options-x).each { |s|
        $combos << x + [s]
      } 
    end
    dli = []
    
    $combos.each_with_index do |a,i|
      next if (bignum % a[-1] != 0)
      if $start.has_key?(a[-1])
        t = $start[a[-1]]
        if $dist[a[-1]] == a.size
          already_there = false
          t.each do |z|
            (already_there = true; break;) if (z-a).size == 0
          end
          if already_there == true
            dli << i
          else
            $start[a[-1]]=t+[a]
          end
        end
      else
        $start[a[-1]]=[a]
        $dist[a[-1]]=a.size
      end
    end
    dli.reverse.each {|z| $combos.delete_at(z)}
  }

  if $use_caches
    File.open("start-#{$bot}.yml", "w") do |file|
      file.write $start.to_yaml
    end
    File.open("dist-#{$bot}.yml", "w") do |file|
      file.write $dist.to_yaml
    end
  end

  $stderr.puts "Done."

end

def go_up(num,remaining,moves_available)
  puts "Going up from: #{num}'s start arrays to find: #{remaining} - in_moves:#{moves_available}"
  $combos = $start[num]
  $combos.to_s
  # init check
  depth = moves_available - $dist[num]
  # to big search - break down further then search again.
  
  best_remaining = remaining.size
  $combos.each{|z|
    return $dist[num],z if (remaining - z).empty?
    best_remaining = (remaining - z).size if (remaining - z).size < best_remaining
  }
  return false,false if depth < best_remaining
  return true if depth > 4
  1.upto(depth) { |loop|
    puts "Level: " + loop.to_s
    temp = $combos
    $combos = []
    min_rem = remaining.size
    temp.each do |x|
      if loop == 1
        options = opt(x).to_set
      else
        options = opt_last(x).to_set
      end
      #(options-x).select{|z| z <= num}.each { |s|
      #min_rem = (remaining - options.to_a).size if (remaining - options.to_a).size < min_rem
      next if (remaining - options.to_a).size > (depth - loop)
      (options-x).each { |s|
        #puts "Adding: " + (x + [s]).to_s
        (puts "Found: #{x + [s]}";return $dist[num]+loop,x + [s];) if (remaining - x - [s]).empty?
        $combos << x + [s]
      } 
    end
    return false,false if $combos.empty?
    #puts "min_rem: " + min_rem.to_s
    #puts "num to go: " + (depth - loop).to_s
    #return false,false if min_rem > (depth - loop)
    #$combos.each{|q| puts q.to_s }
  }

  puts "Done."
  return false, false
end

def go_up_pairs(num,pairs,moves_available)
  puts "Going up from: #{num}'s start arrays to find one of: #{pairs.size} pairs - in_moves:#{moves_available}"
  $combos = $start[num]
  $combos.to_s
  # init check
  depth = moves_available - 8
  # to big search - break down further then search again.
  1.upto(depth) { |loop|
    puts "Level: " + loop.to_s
    $stderr.puts "Level: " + loop.to_s
    temp = $combos
    $combos = []
    temp.each do |x|
      options = opt(x).to_set
      
      (options-x).select{|v| $target % v == 0}.each { |s|
        #puts "Adding: " + (x + [s]).to_s
        $combos << x + [s]
      } 
    end
    return false,false if $combos.empty?
    #puts "min_rem: " + min_rem.to_s
    #puts "num to go: " + (depth - loop).to_s
    #return false,false if min_rem > (depth - loop)
    #$combos.each{|q| puts q.to_s }
  }
  allpairs = pairs.flatten.uniq
  l = $combos.select{|d| d.size != (d-allpairs).size }
  
  $stderr.puts "Post check #{l.size}"
  $stderr.puts "Post check #{pairs.size}"
  l.each do |x|
    pairs.each do |p|
      puts "Checking pair #{p} with #{x}"
      (puts "Found! p:#{p}: #{x + [s]}";return 8+loop,x;) if (p - x).empty?
    end
  end

  puts "Done."
  return false, false
end



def valid?(array)
  return false if array[0] != 1
  1.upto(array.size - 1) do |num|
    found = false
    array[0...num].reverse.each do |x|    
      array[0...num].reverse.each do |y|
        (found = true;break;) if x * y == array[num]
        (found = true;break;) if x + y == array[num]
        (found = true;break;) if x - y == array[num]
        (found = true;break;) if y - x == array[num]
      end
      break if found
    end
    return false unless found
  end
  return true
end

