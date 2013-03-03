module BootstrapVmcPlugin
  module Infrastructure
    class Aws
      LIGHT_STEMCELL_URL = "http://bosh-jenkins-artifacts.s3.amazonaws.com/last_successful_bosh-stemcell_light.tgz"
      def self.bootstrap
        sh("git clone http://github.com/cloudfoundry/cf-release #{cf_release_path}") unless Dir.exist?(cf_release_path)
        sh("cd #{cf_release_path} && ./update")
        sh("cd #{cf_release_path} && bosh -n create release --force && bosh -n upload release")
        sh("cd /tmp && rm -f #{LIGHT_STEMCELL_URL.split("/").last} && wget '#{LIGHT_STEMCELL_URL}'")
        BootstrapVmcPlugin::Generator.new("aws_vpc_receipt.yml", "aws_rds_receipt.yml").save
        template_file = File.expand_path(File.join(File.dirname(__FILE__),'..','..','..','templates','cf-aws-template.yml.erb'))
        sh("bosh -n diff #{template_file}")
        sh("bosh -n deployment cf-aws.yml")
        sh("bosh -n deploy")
      end

      private
      def self.cf_release_path
        '/tmp/cf-release'
      end

      def self.sh(cmd)
        raise "Failed to run #{cmd}" unless system(cmd)
      end
    end
  end
end
