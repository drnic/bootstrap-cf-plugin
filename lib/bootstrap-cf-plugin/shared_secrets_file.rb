require "haddock"

module BootstrapCfPlugin
  class SharedSecretsFile
    PASSWORD_LENGTH = 18
    def self.random_string
      Haddock::Password.delimiters = %q#`~!@$%^&*()-_=+[{]}\;:'",<.>/?#
      Haddock::Password.generate(PASSWORD_LENGTH)
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
