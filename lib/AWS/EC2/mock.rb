module AWS
  module EC2
    class Mock
      def method_missing method, *args
        puts "#{self.class}.#{method} #{args.inspect}"
      end
    end
  end
end
