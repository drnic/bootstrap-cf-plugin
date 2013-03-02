require 'spec_helper'

describe BootstrapVmcPlugin::Generator do
  let(:aws_receipt_file) { asset 'aws_receipt.yml' }
  let(:rds_receipt_file) { asset 'rds_receipt.yml' }
  subject { BootstrapVmcPlugin::Generator.new(aws_receipt_file, rds_receipt_file) }
  it "should generate the expected YAML output" do
    subject.stub!(:director_uuid).and_return("12345-12345-12345")
    Dir.chdir("/tmp") do
      subject.save
      YAML.load_file('cf-aws.yml').should == YAML.load_file(asset 'expected_cf_stub.yml')
    end
  end
end
