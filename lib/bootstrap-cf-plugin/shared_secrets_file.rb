require "securerandom"

module BootstrapCfPlugin
  class SharedSecretsFile
    def self.random_string
      SecureRandom.hex(6)
    end

    def self.find_or_create(filename)
      template_path = File.join(File.dirname(__FILE__), "..", "..", "templates", "cf-shared-secrets.yml.erb")
      unless File.exists?(filename)
        File.open(filename, "w") do |f|
          f.write ERB.new(File.read(template_path)).result(binding)
        end
      end
    end
  end
end
