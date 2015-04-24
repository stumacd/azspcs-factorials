require 'prime'
require 'set'
require 'yaml'

ABANDON_SEARCH = 100000000000
LOW_LIMIT = 50

$factors_cache = {}

class Integer
  def factorial_recursive
    self <= 1 ? 1 : self * (self - 1).factorial
  end
  def factorial_iterative
    f = 1; for i in 1..self; f *= i; end; f
  end
  alias :factorial :factorial_iterative

  def generate_high_limit
    return [] if self == 1
    factor = (2..self).find {|x| return ["prime"] if x > ABANDON_SEARCH; self % x == 0} 
    #factor = (2..self).find {|x| self % x == 0} 
    [factor] + (self / factor).generate_high_limit
  end

  def generate_low_limit
    return [] if self == 1
    factor = (2..self).find {|x| return ["prime"] if x > LOW_LIMIT; self % x == 0} 
    [factor] + (self / factor).generate_low_limit
  end

  def generate
    return [] if self == 1
    factor = (2..self).find {|x| self % x == 0} 
    [factor] + (self / factor).generate
  end

  def factors
    puts "Getting factors: " + self.to_s
    temp = $factors_cache[self]
    return temp unless temp.nil?
    a = self.generate
    return [1] if a.include?("prime")
    b = a.uniq
    d = []
    b.each {|c| d << a.count(c) }
    #puts "Diving in"
    return $factors_cache[self] = find_factors(b,d,0,1)
  end

  def factors_sqrt
    puts "Getting factors sqrt:" + self.to_s
    a = self.generate
    return [1] if a.include?("prime")
    b = a.uniq
    d = []
    b.each {|c| d << a.count(c) }
    sqrt = Math.sqrt(self).ceil
    #puts "Diving in"
    find_factors_sqrt(b,d,0,1,sqrt)
  end
end

class Array

  def sum
      self.inject{|sum,x| sum + x }
  end

  def mean 
      self.sum.to_i / self.size
  end

  def mult
      self.inject{|sum,x| sum * x }
  end

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

def factors_under_sqrt(a)
  return $cache["#{a}"] || $cache["#{a}"] = a.factors_sqrt.select{|x| (x < (a**0.5).ceil + 1)}.sort.reverse - [1,2]
end

def find_factors(prime_divisors, multiplicity, current_divisor, current_result)
    res = []
    if (current_divisor == prime_divisors.length)
        # no more balls
        return [current_result]
    end
    # how many times will we take current divisor?
    # we have to try all options
    i = 0
    #exit
    while (i < (multiplicity[current_divisor] + 1)) do
        res = res + find_factors(prime_divisors, multiplicity, current_divisor + 1, current_result)
        current_result *= prime_divisors[current_divisor]
        i+=1
    end
    return res
end

def find_factors_sqrt(prime_divisors, multiplicity, current_divisor, current_result,sqrt)
    res = []
    if (current_divisor == prime_divisors.length)
        # no more balls
        return [current_result]
    end
    # how many times will we take current divisor?
    # we have to try all options
    i = 0
    #exit
    while (i < (multiplicity[current_divisor] + 1)) do
        res = res + find_factors_sqrt(prime_divisors, multiplicity, current_divisor + 1, current_result,sqrt)
        current_result *= prime_divisors[current_divisor]
        return res if current_result > sqrt
        i+=1
    end
    return res
end
