require File.dirname(__FILE__) + '/../../spec_helper'

describe "Process Memory check" do

  before :each do
    @c = C.p1.merge(
      :checks => C.check_mem
    )
  end

  it "should start periodical watcher" do
    start_ok_process(@c)

    @process.watchers.keys.should == [:check_alive, :check_memory]

    @process.stop

    # after process stop should remove watcher
    @process.watchers.keys.should == []
  end

  describe "1 times" do
    before :each do
      @check = {:memory => {:every => 2, :below => 40.megabytes, :times => 1, :type => :memory}}
    end

    it "when memory exceed limit process should restart" do
      start_ok_process(@c.merge(:checks => @check))
      stub(Eye::SystemResources).memory(@process.pid){ 20_000 }

      sleep 3

      stub(Eye::SystemResources).memory(@process.pid){ 50_000 }      
      mock(@process).notify(:crit, anything)
      mock(@process).schedule(:restart, anything)

      sleep 1
    end

    it "else should not restart" do
      start_ok_process(@c.merge(:checks => @check))

      stub(Eye::SystemResources).memory(@process.pid){ 20_000 }
      sleep 3

      stub(Eye::SystemResources).memory(@process.pid){ 25_000 }
      dont_allow(@process).schedule(:restart)

      sleep 1
    end
  end

  describe "3 times" do
    before :each do
      @check = {:memory => {:every => 2, :below => 40.megabytes, :times => 3, :type => :memory}}
    end

    it "when memory exceed limit process should restart" do
      start_ok_process(@c.merge(:checks => @check))

      stub(Eye::SystemResources).memory(@process.pid){ 20_000 }
      sleep 3

      stub(Eye::SystemResources).memory(@process.pid){ 50_000 }      
      mock(@process).schedule(:restart, anything)

      sleep 6
    end

    it "else should not restart" do
      start_ok_process(@c.merge(:checks => @check))

      stub(Eye::SystemResources).memory(@process.pid){ 20_000 }
      sleep 3

      stub(Eye::SystemResources).memory(@process.pid){ 25_000 }      
      dont_allow(@process).schedule(:restart)

      sleep 6
    end
  end

  describe "3,5 times" do
    before :each do
      @check = {:memory => {:every => 2, :below => 40.megabytes, :times => [3,5], :type => :memory}}
    end

    it "when memory exceed limit process should restart" do
      start_ok_process(@c.merge(:checks => @check))

      stub(Eye::SystemResources).memory(@process.pid){ 20_000 }
      sleep 5

      stub(Eye::SystemResources).memory(@process.pid){ 50_000 }
      mock(@process).schedule(:restart, anything)

      sleep 6
    end

    it "else should not restart" do
      start_ok_process(@c.merge(:checks => @check))

      stub(Eye::SystemResources).memory(@process.pid){ 20_000 }
      sleep 5

      stub(Eye::SystemResources).memory(@process.pid){ 25_000 }
      dont_allow(@process).schedule(:restart)

      sleep 6   
    end
  end

end
