module BootstrapCfPlugin
  class Generator
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
      bosh_target = YAML.load_file(File.join(ENV["HOME"], ".bosh_config"))["target"]
      YAML.load(Net::HTTP.get(URI.parse("#{bosh_target}/info")))["uuid"]
    end

    def micro_ip
      @aws_receipt["elastic_ips"]["micro"]["ips"][0]
    end

    def availability_zone
      @aws_request["vpc"]["subnets"]["bosh"]["availability_zone"]
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

    def to_hash(upstream_manifest, release_name)
      hash = YAML.load ERB.new(File.read(File.expand_path('../../../templates/cf-aws-stub.yml.erb', __FILE__)), 0, "-%<>").result(binding)
      hash["releases"][0]["name"] = release_name
      hash["properties"].merge!(@rds_receipt["deployment_manifest"]["properties"])

      if upstream_manifest
        hash["properties"].merge!(shared_properties(upstream_manifest))
      end

      # this is a hack until the ccdb_ng yaml reference is removed from the vpc template
      # (the yaml marshalling will generate a ccdb_ng: *ccdb line)
      hash["properties"]["ccdb_ng"] = hash["properties"]["ccdb"]
      hash
    end

    def save(manifest_name, upstream_manifest, release_name)
      File.open(manifest_name, "w+") do |f|
        f.write(YAML.dump(to_hash(upstream_manifest, release_name)))
      end
    end

    private

    def shared_properties(shared_manifest)
      upstream_properties = load_yaml_file(shared_manifest)
      return {} unless upstream_properties["properties"] &&
        upstream_properties["properties"]["uaa"] &&
        upstream_properties["properties"]["uaa"]["scim"]
      {
        "uaa"=> {
          "scim"=> {
            "users"=> upstream_properties["properties"]["uaa"]["scim"]["users"]
          }
        }
      }
    end
  end
end
