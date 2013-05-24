module BootstrapCfPlugin::Infrastructure
  class GeneratorBase
    # Save a generated manifest to a file
    def save(manifest_name, upstream_manifest)
      File.open(manifest_name, "w+") do |f|
        f.write(YAML.dump(to_hash(upstream_manifest)))
      end
    end

    def manifest_stub(manifest_name)
      manifest_stub_file = manifest_name.gsub(/(.*)\.yml$/, '\1-stub.yml.erb')
      File.join(templates_dir, manifest_stub_file)
    end

    def infrastructure_name
      raise "Please implement in subclass"
    end

    protected

    def templates_dir
      File.expand_path("../../../../templates", __FILE__)
    end

    def to_hash(upstream_manifest)
      manifest_stub = File.join(templates_dir, "cf-#{infrastructure_name}-stub.yml.erb")
      hash = YAML.load ERB.new(File.read(manifest_stub)).result(binding)
      hash["properties"].merge!(@rds_receipt["deployment_manifest"]["properties"])

      if upstream_manifest
        hash["properties"].merge!(load_yaml_file(upstream_manifest)["properties"])
      end
      hash
    end
  end
end