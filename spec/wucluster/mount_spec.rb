require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe 'Wucluster::Mount' do
  it 'creates' do
    cluster = Wucluster::Mount.new()
  end

  # imperatives:  attach!, detach!, instantiate!, delete!
  # volume: instantiated, instantiating, deleting, absent
  # relationship: attached, attaching, detaching, detached (or volume instantiating, deleting or absent)

  describe 'with state' do
    before do
      @mount = Wucluster::Mount.new('cl', 'ro', 'n_idx', 'n_v_idx', 'dev', 'mount_point' 'vol_0')
      @volume = mock 'mount_vol'
      @mount.stub(:volume).and_return @volume
    end
    it 'is     ready if its volume is instantiated and attached' do
      @mount.should_receive(:instantiated?).and_return(true)
      @mount.should_receive(:attached?).and_return(true)
      @mount.ready?.should be_true
    end
    it 'is not ready if its volume is not instantiated ' do
      @mount.stub(:instantiated?).and_return(false)
      @mount.stub(:attached?).and_return(true)
      @mount.ready?.should be_false
    end
    it 'is not ready if its volume is not attached' do
      @mount.stub(:instantiated?).and_return(true)
      @mount.stub(:attached?).and_return(false)
      @mount.ready?.should be_false
    end

    it 'is     separated when its volume is instantiated and detached' do
      @mount.should_receive(:instantiated?).at_least(:once).and_return(true)
      @mount.stub(:instantiating?).and_return(false)
      @mount.should_receive(:detached?).and_return(true)
      @mount.separated?.should be_true
    end
    it 'is not separated when its volume is instantiated and not detached' do
      @mount.should_receive(:instantiated?).at_least(:once).and_return(true)
      @mount.stub(:instantiating?).and_return(false)
      @mount.should_receive(:detached?).and_return(false)
      @mount.separated?.should be_false
    end
    it 'is     separated when is not instantiated and not instantiating' do
      @mount.should_receive(:instantiated?).at_least(:once).and_return(false)
      @mount.should_receive(:instantiating?).and_return(false)
      @mount.stub(:detached?).and_return(true)
      @mount.separated?.should be_true
    end
    it 'is not separated when it is instantiating' do
      @mount.should_receive(:instantiated?).at_least(:once).and_return(false)
      @mount.should_receive(:instantiating?).and_return(true)
      @mount.stub(:detached?).and_return(true)
      @mount.separated?.should be_false
    end

    [
      :attach!,    :detach!,    :delete!,
      :attached?,  :detached?,
      :attaching?, :detaching?, :instantiating?,
    ].each do |method|
      it "delegates #{method} to its volume" do
        @volume.should_receive(method).and_return 'fnord'
        @mount.send(method).should == 'fnord'
      end
    end

    it 'is     instantiated when its volume is instantiated and it is '
    it 'is not instantiated when its volume is instantiating, deleting or absent'
    #
    it 'is not instantiated when its volume is not in the list of all volumes'
    it 'is not absent when its volume is in the list of all volumes'

    #
    # it 'is painted dirty after any imperative (attach!, detach!, instantiate!, delete!)'
    # [:attached?, :detached?, :attaching?, :detaching?, :instantiating?, :instantiated?].each do |method|
    #   it "on #{method} refreshes its volume if dirty" do
    #     @mount.should_receive(:refresh_if_dirty!)
    #     @volume.stub(method).and_return(true)
    #     @mount.send(method)
    #   end
    # end
  end

  # imperatives:  attach!, detach!, instantiate!, delete!
  # volume:       instantiated, instantiating, deleting, absent
  # relationship: attached, attaching, detaching, detached (or volume instantiating, deleting or absent)

  describe 'when asked to attach!' do
    it 'will attach its volume if instantiated and detached'
    it 'will do nothing     if instantiated and attached or attaching'
    it 'will raise an error if detaching'
    it 'will raise an error if instantiating, deleting or absent'
  end

  describe 'when asked to detach!' do
    it 'will detach its volume if instantiated and attached'
    it 'will do nothing        if instantiated and detaching or detached'
    it 'will do nothing        if deleting or absent'
    it 'will raise an error    if instantiating'
  end

  describe 'when asked to instantiate' do
    it 'will instantiate its volume if absent'
    it 'will do nothing     if instantiating or instantiated'
    it 'will raise an error if deleting'
  end

  describe 'when asked to delete' do
    it 'will delete its volume if instantiated and detached'
    it 'will raise an error if attached, attaching or detaching'
    it 'will raise an error if instantiating'
    it 'will do nothing     if deleting or absent'
  end

  describe 'has snapshots such that' do
    it 'can be snapshotted'
    it ''
    #
    it 'is     recently snapshotted when it has a snapshot and the snapshot is  less  than two hours old'
    it 'is not recently snapshotted when it has a snapshot and the snapshot is *more* than two hours old'
    it 'is not recently snapshotted when it does not have a snapshot'
  end
end
