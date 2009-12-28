require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe 'Wucluster::Cluster' do
  it 'creates' do
    @cluster = Wucluster::Cluster.new(:test)
  end

  describe 'in action' do
    before do
      @cluster = Wucluster::MockCluster.new(:test)
      @node  = mock 'node';  @nodes  = [@node]
      @mount = mock 'mount'; @mounts = [@mount]
      @cluster.stub(:nodes ).and_return(@nodes)
      @cluster.stub(:mounts).and_return(@mounts)
    end

    #
    # Make ready
    #
    it 'to make ready should instantiate its nodes and mounts, then attach mounts to nodes' do
      @cluster.should_receive(:instantiate!)
      @cluster.should_receive(:attach!)
      @cluster.make_ready!
    end
    it 'is ready when all nodes are ready and all mounts are ready' do
      @cluster.should_receive(:are_all).with(@nodes).and_return(true)
      @cluster.should_receive(:are_all).with(@mounts).and_return(true)
      @cluster.ready?.should be_true
    end
    it 'is not ready when aa node is not ready' do
      @node.should_receive(:ready?).and_return(false)
      @mount.stub(:ready?).and_return(true)
      @cluster.ready?.should be_false
    end
    it 'is not ready when any mount is not ready' do
      @node.stub(:ready?).and_return(true)
      @mount.should_receive(:ready?).and_return(false)
      @cluster.ready?.should be_false
    end

    #
    # Put away
    #
    it 'to put away should separate, ensure a recent snapshot, and then delete' do
      @cluster.should_receive(:separate!)
      @cluster.should_receive(:snapshot!)
      @cluster.should_receive(:delete!)
      @cluster.put_away!
    end
    it 'is away when all nodes are away and all mounts are away' do
      @cluster.should_receive(:are_all).with(@nodes).and_return(true)
      @cluster.should_receive(:are_all).with(@mounts).and_return(true)
      @cluster.away?.should be_true
    end
    it 'is not away when any node is not away' do
      @node.should_receive(:away?).and_return(false)
      @mount.stub(:away?).and_return(true)
      @cluster.away?.should be_false
    end
    it 'is not away when any mount is not away' do
      @node.stub(:away?).and_return(true)
      @mount.should_receive(:away?).and_return(false)
      @cluster.away?.should be_false
    end

    #
    # instantiation
    #
    it 'while instantiating, asks each node to instantiate until instantiated' do
      @node.should_receive(:instantiate!).exactly(3).times
      @node.should_receive(:instantiated?).exactly(3).times.and_return(false, false, true)
      @mount.stub(:instantiate!)
      @mount.stub(:instantiated?).and_return(true)
      @cluster.instantiate!
    end
    it 'while instantiating, asks each mount to instantiate until instantiated' do
      @node.stub(:instantiate!)
      @node.stub(:instantiated?).and_return(true)
      @mount.should_receive(:instantiate!).exactly(3).times
      @mount.should_receive(:instantiated?).exactly(3).times.and_return(false, false, true)
      @cluster.instantiate!
    end

    #
    # attaching
    #
    it 'while attaching, asks each mount to attach until attached' do
      @mount.should_receive(:attach!).exactly(3).times
      @mount.should_receive(:attached?).exactly(3).times.and_return(false, false, true)
      @cluster.attach!
    end

    #
    # separating
    #
    it 'while separating, asks each mount to separate until separated' do
      @mount.should_receive(:separate!).exactly(3).times
      @mount.should_receive(:separated?).exactly(3).times.and_return(false, false, true)
      @cluster.separate!
    end

    #
    # deleting
    #
    it 'while deleting, asks each node to delete until deleted' do
      @cluster.should_receive(:separated?).and_return(true)
      @mount.should_receive(:recently_snapshotted?).and_return(true)
      @node.should_receive(:delete!).exactly(3).times
      @node.should_receive(:deleted?).exactly(3).times.and_return(false, false, true)
      @mount.stub(:delete!)
      @mount.stub(:deleted?).and_return(true)
      @cluster.delete!
    end
    it 'while deleting, asks each mount to delete until deleted' do
      @cluster.should_receive(:separated?).and_return(true)
      @mount.should_receive(:recently_snapshotted?).and_return(true)
      @node.stub(:delete!)
      @node.stub(:deleted?).and_return(true)
      @mount.should_receive(:delete!).exactly(3).times
      @mount.should_receive(:deleted?).exactly(3).times.and_return(false, false, true)
      @cluster.delete!
    end
    it 'will raise an error if you try to delete while not separated' do
      @cluster.stub(:recently_snapshotted?).and_return(true)
      @cluster.should_receive(:separated?).and_return(false)
      lambda{ @cluster.delete! }.should raise_error(Exception)
    end
    it 'will raise an error if you try to delete while not recently snapshotted' do
      @cluster.stub(:separated?).and_return(true)
      @cluster.should_receive(:recently_snapshotted?).and_return(false)
      lambda{ @cluster.delete! }.should raise_error(Exception)
    end
  end
end
