require "spec_helper"

describe BootstrapCfPlugin::SharedSecretsFile do
  let(:filename) { "cf-shared-secrets.yml" }
  around do |example|
    Dir.chdir(Dir.mktmpdir) do
      example.run
    end
  end

  describe "#find_or_create" do
    context "when there is not an existing file" do
      it "should create one with valid 12-character passwords" do
        BootstrapCfPlugin::SharedSecretsFile.find_or_create(filename)
        secrets = YAML.load_file(filename)
        users = secrets.fetch("properties").fetch("uaa").fetch("scim").fetch("users")
        users.should have(2).items
        users[0].split("|")[1].length.should == 12
      end
    end

    context "when there is an existing file" do
      it "should not recreate it" do
        File.open filename, "w" do |f|
          f.write("already_here")
        end
        BootstrapCfPlugin::SharedSecretsFile.find_or_create(filename)
        File.read(filename).should == "already_here"
      end
    end
  end

  describe "#random_string" do
    it "should create a 12 character random string" do
      BootstrapCfPlugin::SharedSecretsFile.random_string.length.should == 12
    end
  end
end
