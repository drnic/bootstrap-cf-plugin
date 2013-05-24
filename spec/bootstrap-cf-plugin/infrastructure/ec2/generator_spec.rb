require 'spec_helper'
require "bootstrap-cf-plugin/infrastructure/ec2/generator"

describe BootstrapCfPlugin::Infrastructure::Ec2::Generator do
  let(:aws_receipt_file) { asset("ec2/aws_receipt.yml") }
  let(:rds_receipt_file) { asset("ec2/rds_receipt.yml") }
  subject do
    BootstrapCfPlugin::Infrastructure::Ec2::Generator.new(aws_receipt_file, rds_receipt_file)
  end

  describe "#save" do
    let(:generated_manifest) do
      Dir.chdir("/tmp") do
        subject.save('cf-ec2.yml', upstream_manifest)
        YAML.load_file('cf-ec2.yml')
      end
    end

    before do
      mock(subject).director_uuid { "12345-12345-12345" }
    end

    context "when no upstream manifest is provided" do
      let(:upstream_manifest) { nil }

      it "generates the expected YAML output" do
        generated_manifest.should == YAML.load_file(asset("ec2/expected_cf_stub.yml"))
      end

      it 'gets both CF and Services AZ' do
        generated_manifest["properties"]["template_only"]["aws"]["availability_zone"].should == "us-east-1d"
      end
    end

    context "when an upstream manifest is provided" do
      let(:upstream_manifest) { asset("shared_manifest.yml") }

      it "includes properties from that manifest" do
        generated_manifest.should == YAML.load_file(asset("ec2/expected_cf_stub_with_secrets.yml"))
      end

      it 'gets both CF and Services AZ' do
        generated_manifest["properties"]["template_only"]["aws"]["availability_zone"].should == "us-east-1d"
      end
    end
  end

  describe "manifest_stub" do
    let(:manifest_name) { "some-manifest.yml"}

    it "sets the stub name" do
      subject.manifest_stub(manifest_name).should match(/templates\/some-manifest-stub.yml.erb$/)
    end
  end
end
