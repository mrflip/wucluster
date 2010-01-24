module Wucluster
  #
  # Facade for an EBS Snapshot
  #
  class Ec2Keypair
    include Ec2Proxy

    # Keyname of keypair
    attr_accessor :id
    # Keypair fingerprint
    attr_accessor :fingerprint

    # ===========================================================================
    #
    # Operations
    #

    # return the keypair if it exists, create it otherwise
    def self.exist! id
      find(id.to_s) || create!(id.to_s)
    end

    # start deleting volume
    def delete! options={}
      Log.info "Deleting #{self}"
      response = Wucluster.ec2.delete_keypair options.merge(:key_name => id)
      p response
      Log.warn "Request returned funky existence_status: #{response["return"]}" unless (response["return"] == "true")
      dirty!
    end

    # ===========================================================================
    #
    # API
    #

    # Fetch current state from remote API
    def refresh!
      response = Wucluster.ec2.describe_keypairs(:key_name => id)
      update! response.keySet.item.first
    end

  protected

    def keypair_file_name
      File.join(Settings.private_key_dir, "#{id}.pem")
    end

    def save! private_key_contents
      File.open(keypair_file_name, 'w') do |keypair_file|
        keypair_file << private_key_contents
      end
    end

    def private_key= private_key_contents
      save! private_key_contents
    end

    # Create keypair with given name.
    def self.create! id
      id = id.to_s
      Log.info "Creating #{self} #{id}"
      kp = self.new(:id => id)
      response = Wucluster.ec2.create_keypair(:key_name => id.to_s)
      kp.update! api_hsh_to_params(response)
      kp.dirty!
      kp
    end

    def self.each_api_item &block
      response = Wucluster.ec2.describe_keypairs()
      response.keySet.item.each(&block)
    end

    #
    # Use the hash sent back from AWS to construct an Ec2SecurityGroup instance
    #
    # @example
    #   # response
    #   { "keyName" => "bonobo",
    #     "keyFingerprint"=>"aa:bb:cc:dd:ee:ff:aa:..."}
    def self.api_hsh_to_params api_hsh
      hsh = {
        :id          => api_hsh['keyName'],
        :fingerprint => api_hsh['keyFingerprint'],
        :private_key => api_hsh['keyMaterial']
      }
      hsh
    end

  end
end
