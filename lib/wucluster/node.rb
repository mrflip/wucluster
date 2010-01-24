module Wucluster
  class Node
    # belongs to cluster
    attr_accessor :cluster
    # string identifying logical role
    attr_accessor :role
    # together with the role, uniquely identifies node in cluster
    attr_accessor :node_idx
    # AWS' AMI id for the machine image to use
    attr_accessor :image_id
    # Size of the instance to launch (m1.small | m1.large | m1.xlarge | c1.medium | c1.xlarge | m2.2xlarge | m2.4xlarge)
    attr_accessor :instance_type
    # AWS id for the concrete instance if any
    attr_accessor :instance_id

    def initialize cluster, role, node_idx, image_id, instance_type, instance_id=nil
      self.cluster        = cluster
      self.role           = role
      self.node_idx       = node_idx
      self.image_id       = image_id
      self.instance_type  = instance_type
      self.instance_id    = instance_id
    end

    def self.from_instance instance
      clname, clname_role, clname_role_idx = instance.security_groups.sort
      clname_role_idx ||= 'bonobo-slave-000'
      # check that the security group labels are correct
      cluster_name, role, idx = clname_role_idx.split('-')
      return nil unless (role && idx && clname == cluster_name && clname_role == "#{cluster_name}-#{role}" )
      self.new Cluster.find(cluster_name), role, idx, instance.image_id, instance.instance_type, instance.id
    end

    def to_s
      %Q{#<#{self.class} #{cluster.name}-#{role}-#{"%03d"%node_idx} #{instance_id} #{instance_type} #{image_id} #{status}>}
    end
    def inspect
      to_s
    end

    def status
      instance ? instance.status : :absent
    end

    def refresh!
      instance && instance.refresh!
      self
    end

    def instance
      Wucluster::Ec2Instance.find instance_id
    end

    def instance=(ec2_instance)
      Log.info "Setting instance to #{ec2_instance} from #{@instance_id}"
      @instance_id = ec2_instance ? ec2_instance.id : nil
    end

    # Placement constraints (Availability Zones) for launching the instances.
    def availability_zone
      cluster.availability_zone
    end

    def self.new_from_instance cluster, role, node_idx, instance
      self.new cluster, role, node_idx, instance.image_id, instance.instance_type, instance.id
    end

    # Name of the security group. Act as both logical labels for the instance
    # and define its security policy
    #
    # The nodes label themselves with cluster name and with cluster.name-role
    #
    # @example
    #   cluster = Cluster.new :bonobo
    #   Node.new cluster, :master, 0,
    def security_groups
      [cluster.name.to_s, "#{cluster.name}-#{role}", "#{cluster.name}-#{role}-#{"%03d"%node_idx}"]
    end

    # The name of the AWS key pair, used for remote access to instance
    def key_name
      cluster.name.to_s
    end

    def run!
      case
      when instance.nil? || instance.terminated?
        Ec2Keypair.exist! key_name
        security_groups.each{|sg| Ec2SecurityGroup.exist! sg, "Label for #{cluster.name} #{role} node ##{"%03d"%node_idx}" }
        self.instance = Wucluster::Ec2Instance.create!({
            :image_id          => image_id,
            :key_name          => key_name,
            :security_groups   => security_groups,
            :availability_zone => availability_zone,
            :instance_type     => instance_type,
          })
      when instance.running?        then true
      when instance.pending?        then :wait
      when instance.shutting_down?  then :wait
      else raise UnexpectedState, volume.status.to_s
      end
    end
    def running?
      instance && instance.running?
    end

    # As appropriate, start or run the instance
    def create!
      run!
    end
    # synonym for running?
    def created?
      running?
    end

    # Terminate the instance.
    def terminate!
      case
      when terminated?              then true
      when running?                 then instance.terminate!
      when instance.shutting_down?  then :wait
      when instance.pending?        then :wait
      when instance.error?          then :error
      else raise UnexpectedState, volume.status.to_s
      end
    end

    def terminated?
      instance.nil? || instance.terminated?
    end

    # As appropriate, stop or terminate the instance if it's running
    def delete!()
      terminate!
    end
    def deleted?
      terminated?
    end

  end
end
