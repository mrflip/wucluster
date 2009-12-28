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
      @mount = Wucluster::MockVolume.new('vol_0')
      @volume = mock 'mount_vol'
      @mount.volume = @volume
    end
    it 'is not ready when its volume is instantiated and attaching, detaching or detached'
    it 'is not ready when its volume is instantiating, deleting or absent'
    #
    it 'is     instantiated when its volume is instantiated and it is attaching or attached'
    it 'is     instantiated when its volume is instantiated and it is detaching or detached'
    it 'is not instantiated when its volume is instantiating, deleting or absent'
    #
    it 'is     separated when its volume is instantiated and detached'
    it 'is not separated when its volume is attached, attaching or detaching'
    it 'is     separated when its volume is absent or deleting'
    it 'is not separated when its volume is instantiating'
    #
    it 'is     absent when its volume is not in the list of all volumes'
    it 'is not absent when its volume is in the list of all volumes'
    #
    it 'is painted dirty after any imperative (attach!, detach!, instantiate!, delete!)'
    it 'on any request for state,     refreshes    its volume if it is dirty'
    it 'on any request for state, does not refresh its volume if it is dirty'
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
