require 'spec_helper'

describe BootstrapVmcPlugin::Plugin do

  let(:command) { Mothership.commands[:bootstrap] }
  before do
    BootstrapVmcPlugin::Infrastructure::Aws.stub(:bootstrap)
    Mothership.commands[:login].stub(:invoke)
    Mothership.commands[:logout].stub(:invoke)
    Mothership.commands[:target].stub(:invoke)
    Mothership.commands[:create_space].stub(:invoke)
    Mothership.commands[:create_org].stub(:invoke)

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

  it "should throw an error when the infrastructure is not AWS" do
    expect {
      command.invoke({:infrastructure => "AWZ"})
    }.to raise_error("Unsupported infrastructure AWZ")
  end

  it "should invoke AWS.bootstrap when infrastructure is AWS" do
    BootstrapVmcPlugin::Infrastructure::Aws.should_receive(:bootstrap)
    command.invoke({:infrastructure => "AWS"})
  end

  it 'targets the VMC client' do
    Mothership.commands[:target].should_receive(:invoke).with(:url => "http://example.com")
    command.invoke({:infrastructure => "AWS"})
  end

  it 'logs out and logs in into the VMC' do
    Mothership.commands[:logout].should_receive(:invoke)
    Mothership.commands[:login].should_receive(:invoke).with(:username => 'user', :password => 'da_password')
    command.invoke({:infrastructure => "AWS"})
  end

  it 'VMC creates an Organization and a Sapce' do
    Mothership.commands[:create_org].should_receive(:invoke).with(:name => "bootstrap-org")
    command.invoke({:infrastructure => "AWS"})
  end

  it 'VMC creates a Space' do
    Mothership.commands[:create_space].should_receive(:invoke).with(:organization => an_instance_of(CFoundry::V2::Organization), :name => "bootstrap-space")
    command.invoke({:infrastructure => "AWS"})
  end

  it 'VMC targets the org and space' do
    Mothership.commands[:target].should_receive(:invoke).with(:url => "http://example.com", :organization => an_instance_of(CFoundry::V2::Organization), :space => an_instance_of(CFoundry::V2::Space))
    command.invoke({:infrastructure => "AWS"})
  end
end
