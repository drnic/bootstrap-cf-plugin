module BootstrapVmcPlugin
  class DirectorCheck
    def self.check
      raise "Unable to access the director status" unless system("bosh -n status")
    end
  end
end