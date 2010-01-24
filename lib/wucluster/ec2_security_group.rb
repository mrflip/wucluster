module Wucluster
  #
  # Facade for an EBS Snapshot
  #
  class Ec2SecurityGroup
    include Ec2Proxy

    # security group name
    attr_accessor :id
    # security group Description
    attr_accessor :description

    # ===========================================================================
    #
    # Operations
    #

    # Create snapshot for given volume with description provided
    def self.create! id, description
      Log.info "Creating security_group #{id} (#{description})."
      sg = self.new(:id => id, :description => description)
      response = Wucluster.ec2.create_security_group(:group_name => id, :group_description => description)
      sg.update! api_hsh_to_params(response)
      dirty!
      sg
    end

    # ===========================================================================
    #
    # API
    #

    # Fetch current state from remote API
    def refresh!
      response = Wucluster.ec2.describe_security_groups(:group_name => id)
      update! response.securityGroupInfo.item.first
    end

  protected

    def self.each_api_item &block
      response = Wucluster.ec2.describe_security_groups()
      response.securityGroupInfo.item.each(&block)
    end

    #
    # Use the hash sent back from AWS to construct an Ec2SecurityGroup instance
    #
    # @example
    #   # response
    #   { "groupName"=>"yupshotters",
    #     "ownerId"=>"484232731444",
    #     "groupDescription"=>"Yupfront+yupshot slaves",
    #     "ipPermissions"=>{"item"=>[
    #       {"groups"=>nil, "fromPort"=>"22", "toPort"=>"22", "ipRanges"=>{"item"=>[{"cidrIp"=>"0.0.0.0/0"}]}, "ipProtocol"=>"tcp"},
    #     ]},}
    def self.api_hsh_to_params api_hsh
      p api_hsh
      hsh = {
        :id            => api_hsh['groupName'],
        :description   => api_hsh['groupDescription'],
      }
      hsh
    end

  end
end
