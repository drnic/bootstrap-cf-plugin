class BootstrapCfPlugin::Infrastructure::Ec2
  class Generator < BootstrapCfPlugin::Infrastructure::GeneratorBase
    def initialize(aws_receipt_file, rds_receipt_file)
      @aws_receipt = load_yaml_file(aws_receipt_file)
      @rds_receipt = load_yaml_file(rds_receipt_file)
      @aws_request = @aws_receipt["original_configuration"]
    end

    def name
      @aws_request["name"]
    end

    def domain
      @aws_receipt["domain"]
    end

    def availability_zone
      @aws_request["aws"]["availability_zone"]
    end

    def aws_access_key_id
      @aws_receipt["aws"]["access_key_id"]
    end

    def aws_secret_access_key
      @aws_receipt["aws"]["secret_access_key"]
    end

    def infrastructure_name
      "ec2"
    end

    protected
    def to_hash(upstream_manifest)
      hash = super
      # this is a hack cargo-culted from aws/generator.rb's to_hash
      hash["properties"]["ccdb_ng"] = hash["properties"]["ccdb"]
      hash
    end
  end
end