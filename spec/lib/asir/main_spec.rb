require 'asir/main'

describe ASIR::Main do
  let(:main) { ASIR::Main.new }

  context "#server_pid" do
    let(:pid_file) do
      pid_file = "/tmp/#{$$}.#{rand(10000)}.pid"
      File.exist?(pid_file).should == false
      pid_file
    end
    before(:each) { allow(main).to receive(:pid_file).and_return(pid_file) }
    after(:each)  { File.unlink(pid_file) rescue nil }

    it "should return non-true if pid_file does not exist" do
      main.server_pid.should == false
    end

    it "should return non-true if pid_file is empty" do
      File.open(pid_file, "w+") { | fh | }
      main.server_pid.should == nil
    end

    it "should return non-true if pid_file is empty" do
      File.open(pid_file, "w+") { | fh | }
      main.server_pid.should == nil
    end

    it "should return non-true if pid_file has an empty line" do
      File.open(pid_file, "w+") { | fh | fh.puts "" }
      main.server_pid.should == false
    end

    it "should return non-true if pid_file is broken" do
      File.open(pid_file, "w+") { | fh | "asdfsd" }
      main.server_pid.should == nil
    end

    it "should return pid if pid_file contains a pid" do
      File.open(pid_file, "w+") { | fh | fh.puts($$.to_s) }
      main.server_pid.should == $$
    end
  end

  context "#process_running?" do
    it "should return false for invalid values." do
      main.process_running?(nil).should == nil
      main.process_running?(false).should == false
      main.process_running?(0).should == false
      main.process_running?(1).should == false
    end

    it "should return pid for a live process." do
      main.process_running?($$).should == $$
    end
  end
end
