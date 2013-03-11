require "bootstrap-vmc-plugin"

module BootstrapVmcPlugin
  class Plugin < VMC::CLI
    def precondition
      # skip all default preconditions
    end

    def lookup_infrastructure_class(infrastructure)
      infrastructure_module = Kernel.const_get("BootstrapVmcPlugin").const_get("Infrastructure")
      infrastructure_module.const_get(infrastructure) if infrastructure_module.const_defined?(infrastructure)
    end

    desc "Bootstrap a CF deployment"
    group :admin
    input :infrastructure, :argument => :required, :desc => "The infrastructure to bootstrap and deploy"
    def bootstrap
      infrastructure = input[:infrastructure].to_s.capitalize
      infrastructure_class = lookup_infrastructure_class(infrastructure)
      raise "Unsupported infrastructure #{input[:infrastructure]}" unless infrastructure_class
      DirectorCheck.check
      infrastructure_class.bootstrap

      cf_aws_mainfest = load_yaml_file("cf-aws.yml")['properties']
      uaa_users = cf_aws_mainfest['uaa']['scim']['users']

      uaa_user = uaa_users.first.split("|")

      invoke :logout
      invoke :target, :url => cf_aws_mainfest['cc']['srv_api_uri']

      invoke :login, :username => uaa_user[0], :password => uaa_user[1]

      invoke :create_org, :name => 'bootstrap-org'

      org = client.organization_by_name("bootstrap-org")
      invoke :create_space, :organization => org, :name => "bootstrap-space"

      space = client.space_by_name("bootstrap-space")
      invoke :target, :url => cf_aws_mainfest['cc']['srv_api_uri'], :organization => org, :space => space
    end
  end
end
