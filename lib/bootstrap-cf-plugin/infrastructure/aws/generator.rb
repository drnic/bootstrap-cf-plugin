class BootstrapCfPlugin::Infrastructure::Aws
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
      @aws_receipt["vpc"]["domain"]
    end

    def static_ips(name)
      @aws_receipt["elastic_ips"][name]["ips"]
    end

    def director_uuid
      bosh_config = ENV['BOSH_CONFIG'].to_s.empty? ? File.join(ENV["HOME"], ".bosh_config") : ENV['BOSH_CONFIG']
      YAML.load_file(bosh_config)["target_uuid"] || raise("Cannot get UUID from BOSH config #{bosh_config}, make sure you've targeted and logged in")
    end

    def micro_ip
      @aws_receipt["elastic_ips"]["micro"]["ips"][0]
    end

    def availability_zone
      @aws_request["vpc"]["subnets"]["cf1"]["availability_zone"]
    end

    def subnet_id(subnet_name)
      @aws_receipt["vpc"]["subnets"][subnet_name]
    end

    def aws_access_key_id
      @aws_receipt["aws"]["access_key_id"]
    end

    def aws_secret_access_key
      @aws_receipt["aws"]["secret_access_key"]
    end

    def infrastructure_name
      "aws"
    end

    protected
    def to_hash(upstream_manifest)
      hash = super
      # this is a hack until the ccdb_ng yaml reference is removed from the vpc template
      # (the yaml marshalling will generate a ccdb_ng: *ccdb line)
      hash["properties"]["ccdb_ng"] = hash["properties"]["ccdb"]
      hash
    end
  end
end
