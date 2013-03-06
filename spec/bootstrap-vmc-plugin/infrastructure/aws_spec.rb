require 'spec_helper'

describe BootstrapVmcPlugin::Infrastructure::Aws do
  context "#bootstrap" do
    let(:cf_release_path) { "/tmp/spec-cf-release" }
    let!(:working_path) do
      Dir.mktmpdir.tap do |path|
        FileUtils.cp asset("aws_receipt.yml"), File.join(path, "aws_vpc_receipt.yml")
        FileUtils.cp asset("rds_receipt.yml"), File.join(path, "aws_rds_receipt.yml")
      end
    end
    let(:execute_command) do
      Dir.chdir(working_path) do
        BootstrapVmcPlugin::Infrastructure::Aws.bootstrap
      end
    end

    before do
      FileUtils.rm_rf(cf_release_path)
      BootstrapVmcPlugin::Generator.any_instance.stub(:director_uuid).and_return("12345-12345-12345")
      BootstrapVmcPlugin::Infrastructure::Aws.stub(:cf_release_path).and_return(cf_release_path)
      BootstrapVmcPlugin::Infrastructure::Aws.stub(:sh)
    end

    after do
      execute_command
    end

    context "if release doesn't exist" do
      before do
        BootstrapVmcPlugin::Infrastructure::Aws.should_receive(:sh).with("bosh -n releases | tail -1 | grep 'No releases'").and_return(0)
      end

      it 'checkouts the cf-release from github when not present' do
        BootstrapVmcPlugin::Infrastructure::Aws.should_receive(:sh).with('git clone http://github.com/cloudfoundry/cf-release /tmp/spec-cf-release')
      end

      it 'does not checkout the cf-release when present' do
        FileUtils.mkdir_p(cf_release_path)
        BootstrapVmcPlugin::Infrastructure::Aws.should_not_receive(:sh).with('git clone http://github.com/cloudfoundry/cf-release /tmp/spec-cf-release')
      end

      it 'updates the cf-release' do
        BootstrapVmcPlugin::Infrastructure::Aws.should_receive(:sh).with('cd /tmp/spec-cf-release && ./update')
      end

      it 'creates the cf bosh release' do
        BootstrapVmcPlugin::Infrastructure::Aws.should_receive(:sh).with('cd /tmp/spec-cf-release && bosh -n create release --force && bosh -n upload release')
      end
    end

    context "if the release already exists" do
      before do
        BootstrapVmcPlugin::Infrastructure::Aws.should_receive(:sh).with("bosh -n releases | tail -1 | grep 'No releases'").and_raise "Failed to run: bosh -n releases | tail -1 | grep 'No releases'"
      end

      it 'skips the cf-release checkouts ' do
        BootstrapVmcPlugin::Infrastructure::Aws.should_not_receive(:sh).with('git clone http://github.com/cloudfoundry/cf-release /tmp/spec-cf-release')
      end

      it 'skips updating the cf-release' do
        BootstrapVmcPlugin::Infrastructure::Aws.should_not_receive(:sh).with('cd /tmp/spec-cf-release && ./update')
      end

      it 'skips creating the cf bosh release' do
        BootstrapVmcPlugin::Infrastructure::Aws.should_not_receive(:sh).with('cd /tmp/spec-cf-release && bosh -n create release --force && bosh -n upload release')
      end
    end

    context "if the stemcell doesn't exist" do
      before do
        BootstrapVmcPlugin::Infrastructure::Aws.should_receive(:sh).with("bosh -n stemcells | tail -1 | grep 'No stemcells'").and_return(0)
      end

      it 'downloads the latest stemcell from S3' do
        BootstrapVmcPlugin::Infrastructure::Aws.should_receive(:sh).with("cd /tmp && rm -f last_successful_bosh-stemcell_light.tgz && wget 'http://bosh-jenkins-artifacts.s3.amazonaws.com/last_successful_bosh-stemcell_light.tgz'")
      end

      it 'uploads the lastest stemcell' do
        BootstrapVmcPlugin::Infrastructure::Aws.should_receive(:sh).with("bosh -n upload stemcell /tmp/last_successful_bosh-stemcell_light.tgz")
      end
    end

    context "if the stemcell does exist" do
      before do
        BootstrapVmcPlugin::Infrastructure::Aws.should_receive(:sh).with("bosh -n stemcells | tail -1 | grep 'No stemcells'").and_raise "Failed to run: bosh -n stemcells | tail -1 | grep 'No stemcells'"
      end

      it 'skips downloading the stemcell from S3' do
        BootstrapVmcPlugin::Infrastructure::Aws.should_not_receive(:sh).with("cd /tmp && rm -f last_successful_bosh-stemcell_light.tgz && wget 'http://bosh-jenkins-artifacts.s3.amazonaws.com/last_successful_bosh-stemcell_light.tgz'")
      end

      it 'skips uploading the stemcell' do
        BootstrapVmcPlugin::Infrastructure::Aws.should_not_receive(:sh).with("bosh -n upload stemcell /tmp/last_successful_bosh-stemcell_light.tgz")
      end
    end

    context "if the deployment doesn't exist" do
      before do
        BootstrapVmcPlugin::Infrastructure::Aws.should_receive(:sh).with("bosh -n deployments | tail -1 | grep 'No deployments'").and_return(0)
      end

      it 'generates the manifest file - cf-aws.yml' do
        File.should exist(File.join(working_path, "aws_vpc_receipt.yml"))
        execute_command
        File.should exist(File.join(working_path, "cf-aws.yml"))
      end

      it 'applies the template to the manifest file with bosh diff' do
        templates_dir = File.expand_path(File.join(File.dirname(__FILE__), '..','..','..','templates'))
        BootstrapVmcPlugin::Infrastructure::Aws.should_receive(:sh).with("bosh -n diff #{templates_dir}/cf-aws-template.yml.erb")
      end

      it 'sets the bosh deployment' do
        BootstrapVmcPlugin::Infrastructure::Aws.should_receive(:sh).with('bosh -n deployment cf-aws.yml')
      end
    end

    context "if the deployment does exist" do
      before do
        BootstrapVmcPlugin::Infrastructure::Aws.should_receive(:sh).with("bosh -n deployments | tail -1 | grep 'No deployments'").and_raise "Failed to run: bosh -n deployments | tail -1 | grep  'No deployments'"
      end

      it 'skips generating the manifest file - cf-aws.yml' do
        BootstrapVmcPlugin::Generator.should_not_receive(:new)
      end

      it 'skips appling the template to the manifest file with bosh diff' do
        templates_dir = File.expand_path(File.join(File.dirname(__FILE__), '..','..','..','templates'))
        BootstrapVmcPlugin::Infrastructure::Aws.should_not_receive(:sh).with("bosh -n diff #{templates_dir}/cf-aws-template.yml.erb")
      end

      it 'skips setting the bosh deployment' do
        BootstrapVmcPlugin::Infrastructure::Aws.should_not_receive(:sh).with('bosh -n deployment cf-aws.yml')
      end
    end

    it 'does the bosh deploy' do
      BootstrapVmcPlugin::Infrastructure::Aws.should_receive(:sh).with('bosh -n deploy')
    end
  end
end
