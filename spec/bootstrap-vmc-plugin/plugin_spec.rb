require 'spec_helper'

command BootstrapVmcPlugin::Plugin do
  let(:client) { fake_client }

  before do
    stub(BootstrapVmcPlugin::DirectorCheck).check
    stub(BootstrapVmcPlugin::Infrastructure::Aws).bootstrap

    stub_invoke :logout
    stub_invoke :login, anything
    stub_invoke :target, anything
    stub_invoke :create_space, anything
    stub_invoke :create_org, anything
  end


  around do |example|
    Dir.chdir(Dir.mktmpdir) do
      File.open("cf-aws.yml", "w") do |w|
        w.write YAML.dump({
                              "properties" => {
                                  "cc" => {
                                      "srv_api_uri" => "http://example.com"
                                  },
                                 'uaa' => {
                                      'scim' => {
                                            'users' => ["user|da_password"]
                                        }
                                }
                              }
                          })
      end

      example.run
    end
  end

  context "when the infrastructure is not AWS" do
    subject { vmc %W[bootstrap awz] }

    it "should throw an error when the infrastructure is not AWS" do
      expect {
        subject
      }.to raise_error("Unsupported infrastructure awz")
    end
  end

  context "when the infrastructure is AWS" do
    subject { vmc %W[bootstrap aws] }

    describe "verifying access to director" do
      it "should blow up if unable to get director status" do
        stub(BootstrapVmcPlugin::DirectorCheck).check { raise "some error message" }
        dont_allow(BootstrapVmcPlugin::Infrastructure::Aws).bootstrap
        expect {
          subject
        }.to raise_error "some error message"
      end
    end

    it "should invoke AWS.bootstrap when infrastructure is AWS" do
      mock(BootstrapVmcPlugin::Infrastructure::Aws).bootstrap
      subject
    end

    it 'targets the VMC client' do
      mock_invoke :target, :url => "http://example.com"
      subject
    end

    it 'logs out and logs in into the VMC' do
      mock_invoke :logout
      mock_invoke :login, :username => 'user', :password => 'da_password'
      subject
    end

    it 'VMC creates an Organization and a Space' do
      mock_invoke :create_org, :name => "bootstrap-org"
      subject
    end

    context "when the org was created" do
      let(:client) { fake_client :organizations => [bootstrap_org] }

      let(:bootstrap_org) { fake :organization, :name => "bootstrap-org" }

      it 'VMC creates a Space' do
        mock_invoke :create_space, :organization => bootstrap_org, :name => "bootstrap-space"
        subject
      end
    end

    context "when the org and space were created" do
      let(:client) { fake_client :organizations => [bootstrap_org], :spaces => [bootstrap_space] }

      let(:bootstrap_org) { fake :organization, :name => "bootstrap-org" }
      let(:bootstrap_space) { fake :space, :name => "bootstrap-space" }

      it 'VMC targets the org and space' do
        mock_invoke :target, :url => "http://example.com", :organization => bootstrap_org, :space => bootstrap_space
        subject
      end
    end
  end
end