require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Wucluster" do
end

describe 'Wucluster::Cluster' do
  it 'creates' do
    cluster = Wucluster::Cluster.new(:test)
  end

  describe 'when being put away' do
    before do
      @cluster = Wucluster::MockCluster.new(:test)
    end

    # it 'should shut down in order' do
    #   @cluster.should_receive(:instantiate!)
    #   @cluster.should_receive(:attach!)
    #   @cluster.make_ready!
    # end
    #
    # it 'should be ready after it makes reaady' do
    #   @cluster.make_ready!
    #   @cluster.should be_ready
    # end

    it 'should allow no nodes'

    it 'should act on all nodes'
  end

  describe 'when making itself ready' do
    it 'should instantiate its nodes and mounts, then attach mounts to nodes'
    it 'after making itself ready it should be ready'
  end

  describe 'when asked to delete' do
    before do
      @cluster = Wucluster::MockCluster.new(:test)
    end
    it 'will raise an error if you try to delete while not recently snapshotted' do
      @cluster.should_receive(:recently_snapshotted?).and_return(false)
      lambda{ @cluster.delete! }.should raise_error(Exception)
    end
    it 'will delete all its nodes' do
      @cluster.should_receive(:recently_snapshotted?).and_return(true)
      mount = mock 'vol_0';
      mount.stub(:status)
      mount.should_receive(:delete!)
      mount.should_receive(:deleted?).and_return true
      @cluster.stub(:mounts).and_return [mount]
      @cluster.delete!
    end
    it 'will delete all its mounts'
  end

  describe 'with state' do
    it 'is ready when all nodes and mounts are ready'
    it 'is instantiated when all nodes and mounts are instantiated'
    it 'is separated when all nodes and mounts are separated'
    it 'is recently snapshotted when all mounts have been recently snapshotted'
    it 'is deleted when all nodes and mounts are deleted'
  end
end
