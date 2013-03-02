require 'spec_helper'

describe BootstrapVmcPlugin::Plugin do

  let(:command) { Mothership.commands[:bootstrap] }
  before do
    BootstrapVmcPlugin::Infrastructure::Aws.stub(:bootstrap)
    Mothership.commands[:login].stub(:invoke)
    Mothership.commands[:target].stub(:invoke)
  end

  around do |example|
    Dir.chdir(Dir.mktmpdir) do
      File.open("cf-aws.yml", "w") do |w|
        w.write YAML.dump({
                              "properties" => {
                                  "cc" => {
                                      "srv_api_uri" => "http://example.com"
                                  },
                                 'uaadb' => {
                                      'roles' => [ {'tag' => 'admin' ,'name' => 'uaa', 'password' => 'da_password'}]
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

  it 'logins into the VMC' do
    Mothership.commands[:login].should_receive(:invoke).with(:username => 'uaa', :password => 'da_password')
    command.invoke({:infrastructure => "AWS"})
  end
end
