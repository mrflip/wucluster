module Wucluster
  #
  # Facade for an EBS Asset
  #
  module Ec2Proxy

    #
    def update! hsh
      hsh.each do |attr, val|
        self.send("#{attr}=", val)
      end
    end

    def dirty!
      @dirty = true
    end
    def undirty!
      @dirty = false
    end
    def dirty?
      @dirty
    end

    module ClassMethods
      # construct a new volume from the api response
      def new *params
        obj = super(*params)
        register obj
        obj
      end
      #
      def register obj
        @objs_list[obj.id] = obj
      end

      # Remove the object
      def unregister id
        @objs_list.delete id
      end

      # list of all volumes
      def all
        load_all! unless @objs_list
        @objs_list.values
      end

      # Retrieve volume from volumes map, or by querying AWS directly
      def find id
        @objs_list[id]
      end

      # retrieve info for all volumes from AWS
      def load_all!
        Log.info "Loading #{self} list"
        @objs_list = {}
        each_api_item do |api_hsh|
          self.new api_hsh_to_params(api_hsh)
        end
        Log.info "Loaded list of #{@objs_list.length} #{self}s"
        @objs_list
      end
    end

    # standard stunt to create class methods
    def self.included base
      base.class_eval do
        extend ClassMethods
      end
    end
  end
end
