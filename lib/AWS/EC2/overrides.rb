module AWS
  module EC2
    class Base < AWS::Base

      # The CreateSnapshot operation creates a snapshot of an Amazon EBS volume and stores it in Amazon S3. You can use snapshots for backups, to launch instances from identical snapshots, and to save data before shutting down an instance.
      #
      # @option options [String] :volume_id ('')
      #
      def create_snapshot( options = {} )
        options = { :volume_id => '' }.merge(options)
        raise ArgumentError, "No :volume_id provided" if options[:volume_id].nil? || options[:volume_id].empty?
        params = {
          "VolumeId"    => options[:volume_id],
          "Description" => options[:description]
        }
        return response_generator(:action => "CreateSnapshot", :params => params)
      end

    end
  end
end
