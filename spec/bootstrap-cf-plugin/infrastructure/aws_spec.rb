require 'spec_helper'

describe BootstrapCfPlugin::Infrastructure::Aws do
  let!(:temp_dir) { Dir.mktmpdir }

  before do
    any_instance_of(BootstrapCfPlugin::Generator, :director_uuid => "12345-12345-12345")
    stub(described_class).sh

    FileUtils.cp asset("aws_receipt.yml"), File.join(temp_dir, "aws_vpc_receipt.yml")
    FileUtils.cp asset("rds_receipt.yml"), File.join(temp_dir, "aws_rds_receipt.yml")
  end

  after do
    FileUtils.remove_entry_secure(temp_dir)
  end

  def run_bootstrap_command(template_file=nil)
    Dir.chdir(temp_dir) do
      BootstrapCfPlugin::Infrastructure::Aws.bootstrap template_file
    end
  end

  context "::bootstrap" do
    it 'does the bosh deploy' do
      mock(described_class).sh('bosh -n deploy')
      run_bootstrap_command
    end

    describe "releases" do
      let(:cf_release_path) { File.join(Dir.tmpdir, "cf-release") }

      context "if release doesn't exist" do
        before do
          mock(described_class).sh("bosh -n releases | grep -v 'bosh-release'") { 0 }
        end

        it 'checkouts the cf-release from github when not present' do
          stub(Dir).tmpdir { temp_dir }
          mock(described_class).sh("git clone -b release-candidate http://github.com/cloudfoundry/cf-release #{cf_release_path}")
          run_bootstrap_command
        end

        it 'does not checkout the cf-release when present' do
          FileUtils.mkdir_p(cf_release_path)
          dont_allow(described_class).sh("git clone -b release-candidate http://github.com/cloudfoundry/cf-release #{cf_release_path}")
          run_bootstrap_command
        end

        it 'updates the cf-release' do
          mock(described_class).sh("cd #{cf_release_path} && git submodule foreach --recursive git submodule sync && git submodule update --init --recursive")
          run_bootstrap_command
        end

        it 'creates the cf bosh release' do
          mock(described_class).sh("cd #{cf_release_path} && bosh -n create release --force && bosh -n upload release")
          run_bootstrap_command
        end
      end

      context "if the release already exists" do
        before do
          stub(described_class).sh("bosh -n releases | grep -v 'bosh-release'") do
            raise "Failed to run: bosh -n releases | grep -v 'bosh-release'"
          end
        end

        it 'skips the cf-release checkouts ' do
          dont_allow(described_class).sh("git clone http://github.com/cloudfoundry/cf-release #{cf_release_path}")
          run_bootstrap_command
        end

        it 'skips updating the cf-release' do
          dont_allow(described_class).sh("cd #{cf_release_path} && ./update")
          run_bootstrap_command
        end

        it 'skips creating the cf bosh release' do
          dont_allow(described_class).sh("cd #{cf_release_path} && bosh -n create release --force && bosh -n upload release")
          run_bootstrap_command
        end
      end
    end

    describe "stemcells" do
      context "if no stemcell URL override is set in the environment" do
        context "if the stemcell doesn't exist" do
          before do
            mock(described_class).sh("bosh -n stemcells | tail -1 | grep 'No stemcells'") { 0 }
          end

          it 'downloads the latest stemcell from S3' do
            mock(described_class).sh("cd /tmp && rm -f last_successful_bosh-stemcell_light.tgz && wget 'http://bosh-jenkins-artifacts.s3.amazonaws.com/last_successful_bosh-stemcell_light.tgz' --no-check-certificate")
            run_bootstrap_command
          end

          it 'uploads the lastest stemcell' do
            mock(described_class).sh("bosh -n upload stemcell /tmp/last_successful_bosh-stemcell_light.tgz")
            run_bootstrap_command
          end
        end

        context "if the stemcell does exist" do
          before do
            stub(described_class).sh("bosh -n stemcells | tail -1 | grep 'No stemcells'") do
              raise "Failed to run: bosh -n stemcells | tail -1 | grep 'No stemcells'"
            end
          end

          it 'skips downloading the stemcell from S3' do
            dont_allow(described_class).sh("cd /tmp && rm -f last_successful_bosh-stemcell_light.tgz && wget 'http://bosh-jenkins-artifacts.s3.amazonaws.com/last_successful_bosh-stemcell_light.tgz' --no-check-certificate")
            run_bootstrap_command
          end

          it 'skips uploading the stemcell' do
            dont_allow(described_class).sh("bosh -n upload stemcell /tmp/last_successful_bosh-stemcell_light.tgz")
            run_bootstrap_command
          end
        end
      end

      context "if a stemcell URL override is set in the environment" do
        before(:all) do
          ENV["BOSH_OVERRIDE_LIGHT_STEMCELL_URL"] = "http://stemcells-r-us.com/stemcell.tgz"
        end

        after(:all) do
          ENV.delete "BOSH_OVERRIDE_LIGHT_STEMCELL_URL"
        end

        it 'downloads the stemcell at the given URL' do
          mock(described_class).sh("cd /tmp && rm -f stemcell.tgz && wget 'http://stemcells-r-us.com/stemcell.tgz' --no-check-certificate")
          run_bootstrap_command
        end

        it 'uploads the latest stemcell' do
          mock(described_class).sh("bosh -n upload stemcell /tmp/stemcell.tgz")
          run_bootstrap_command
        end
      end
    end

    describe "deployments" do
      context "if the deployment doesn't exist" do
        before do
          stub(described_class).sh("bosh -n deployments | grep -v 'cf-deployment'") { 0 }
        end

        it 'generates the manifest file - cf-aws.yml' do
          File.should exist(File.join(temp_dir, "aws_vpc_receipt.yml"))
          run_bootstrap_command
          File.should exist(File.join(temp_dir, "cf-aws.yml"))
        end

        it 'applies the template to the manifest file with bosh diff' do
          aws_template = File.join(Dir.tmpdir, "cf-release", "templates", "cf-aws-template.yml.erb")
          mock(described_class).sh("bosh -n diff #{aws_template}")
          run_bootstrap_command
        end

        it 'sets the bosh deployment' do
          mock(described_class).sh('bosh -n deployment cf-aws.yml')
          run_bootstrap_command
        end
      end

      context "if the deployment does exist" do
        before do
          fake_generator = stub(stub!.save.subject).name { "deployment" }
          stub(described_class).generator { fake_generator }
          stub(described_class).sh("bosh -n deployments | grep -v 'cf-deployment'") do
            raise "Failed to run: bosh -n deployments | grep -v 'cf-deployment'"
          end
        end

        it 'skips generating the manifest file - cf-aws.yml' do
          dont_allow(BootstrapCfPlugin::Generator).new
          run_bootstrap_command
        end

        it 'skips appling the template to the manifest file with bosh diff' do
          templates_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'templates'))
          dont_allow(described_class).sh("bosh -n diff #{templates_dir}/cf-aws-template.yml.erb")
          run_bootstrap_command
        end

        it 'skips setting the bosh deployment' do
          dont_allow(described_class).sh('bosh -n deployment cf-aws.yml')
          run_bootstrap_command
        end
      end
    end
  end

  context "::bootstrap with custom template file" do
    let(:template_file) { "template.erb" }

    it 'applies the template given with bosh diff' do
      stub(described_class).sh("bosh -n deployments | grep -v 'cf-deployment'") { 0 }
      mock(described_class).sh("bosh -n diff template.erb")
      run_bootstrap_command(template_file)
    end
  end
end
