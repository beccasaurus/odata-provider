# Array#to_hash takes an array like [ [:a,1], [:b,2] ] and turns it into a Hash like { :a => 1, :b => 2 }
#
# This is useful for Ruby 1.8 support where Hash#select and other Hash methods return an Array instead of a Hash
module ArrayToHash
  def to_hash
    self.inject({}){|hash, array| hash[array.first] = array.last; hash }
  end
end

Array.send :include, ArrayToHash

# Hash#to_hash returns the Hash, itself
module HashToHash
  def to_hash() self end
end

Hash.send :include, HashToHash
