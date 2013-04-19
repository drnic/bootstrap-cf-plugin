require 'spec_helper'

describe BootstrapCfPlugin::Generator do
  let(:aws_receipt_file) { asset 'aws_receipt.yml' }
  let(:rds_receipt_file) { asset 'rds_receipt.yml' }
  subject do
    BootstrapCfPlugin::Generator.new(aws_receipt_file, rds_receipt_file)
  end

  it "should generate the expected YAML output" do
    mock(subject).director_uuid { "12345-12345-12345" }
    Dir.chdir("/tmp") do
      subject.save('cf-aws.yml', nil)
      YAML.load_file('cf-aws.yml').should == YAML.load_file(asset 'expected_cf_stub.yml')
    end
  end

  it "should allow access to all of the subnets" do
    subject.subnet_id('cf').should == 'subnet-4bdf6c27'
    subject.subnet_id('bosh').should == 'subnet-4bdf6c26'
    subject.subnet_id('other').should == 'subnet-xxxxxxxx'
  end

  describe "to_hash" do
    let(:upstream_manifest) { asset "shared_manifest.yml" }

    context "when shared manifest is provided" do
      it "merges uaa scim users into current manifest" do
        properties = subject.to_hash("cf-aws.yml", upstream_manifest)["properties"]
        properties.should include({
          "uaa" => {
            "scim" => {
              "users" => [
                "admin|random1passwd|scim.write,scim.read,openid,cloud_controller.admin",
                "service|other4psword|scim.write,scim.read,openid,cloud_controller.admin"
              ]
            }
          }
        })
      end
    end
  end

  describe "manifest_stub" do
    let(:manifest_name) { "some-manifest.yml"}

    it "sets the stub name" do
      subject.manifest_stub(manifest_name).should match /templates\/some-manifest-stub.yml.erb$/
    end
  end
end
