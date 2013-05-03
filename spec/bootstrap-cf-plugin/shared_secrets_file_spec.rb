require "spec_helper"

describe BootstrapCfPlugin::SharedSecretsFile do
  let(:password_length) { 18 }

  let(:filename) { "cf-shared-secrets.yml" }

  around do |example|
    Dir.chdir(Dir.mktmpdir) do
      example.run
    end
  end

  describe "#find_or_create" do
    context "when there is not an existing file" do
      let(:properties) do
        BootstrapCfPlugin::SharedSecretsFile.find_or_create(filename)
        YAML.load_file(filename).fetch("properties")
      end

      let(:secret_params) do
        # non-exhaustive
        [
          properties["uaa"]["scim"]["users"][0].split("|")[1],
          properties["uaa"]["scim"]["users"][1].split("|")[1],
          properties["nats"]["password"],
          properties["cc"]["bulk_api_password"],
          properties["cc"]["db_encryption_key"],
          properties["uaa"]["cc"]["client_secret"]
        ]
      end

      it "fills in every secret field with a password of the right length" do
        secret_params.each do |param|
          param.length.should == password_length
        end
      end

      it "generates a unique password for every secret field" do
        secret_params.should =~ secret_params.uniq
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
    it "never includes a pipe character (because UAA uses that as a delimiter)" do
      50.times do
        BootstrapCfPlugin::SharedSecretsFile.random_string.should_not include('|')
      end
    end
  end
end
