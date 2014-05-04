class Array
  
  def ith_perm(i)
    
    raise "Max perm index is #{self.perms_count - 1}" if i >= perms_count
    n = self.length
    fact = n.factorial
    perm = Array.new(n)
    
    (0..(n - 1)).each do |k|
      perm[k] = i / (n - 1 - k).factorial
      i = i % (n - 1 - k).factorial
    end
    
    (n - 1).downto(1) do |k|
      (k - 1).downto(0) do |j|
        if perm[j] <= perm[k]
          perm[k] += 1
        end
      end
    end
    
    return perm.map{|index| self[index]}
  end
  
  def perms_count
    self.length.factorial
  end
  
end

class Integer
  def factorial
    (2..self).inject(:*) || 1
  end
end