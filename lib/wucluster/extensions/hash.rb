class Hash

  # Instantiate a hash from an array of keys and a parallel array of values
  def self.zip keys, vals, &block
    keys.zip(vals).inject(Hash.new(&block)) do |hsh, kv|
      hsh[kv.first] = kv.last
      hsh
    end
  end

  # Slice a hash to include only the given keys. This is useful for
  # limiting an options hash to valid keys before passing to a method:
  #
  #   def search(criteria = {})
  #     assert_valid_keys(:mass, :velocity, :time)
  #   end
  #
  #   search(options.slice(:mass, :velocity, :time))
  # Returns a new hash with only the given keys.
  def slice(*keys)
    allowed = Set.new(respond_to?(:convert_key) ? keys.map { |key| convert_key(key) } : keys)
    reject{|key,| !allowed.include?(key) }
  end
end
