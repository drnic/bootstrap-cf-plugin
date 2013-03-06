module BootstrapVmcPlugin
  module Infrastructure
    class Aws
      LIGHT_STEMCELL_URL = "http://bosh-jenkins-artifacts.s3.amazonaws.com/last_successful_bosh-stemcell_light.tgz"
      def self.bootstrap
        begin
          puts("Checking for release...")
          sh("bosh -n releases | tail -1 | grep 'No releases'")
          puts("Missing release, creating...")
          sh("git clone http://github.com/cloudfoundry/cf-release #{cf_release_path}") unless Dir.exist?(cf_release_path)
          sh("cd #{cf_release_path} && ./update")
          sh("cd #{cf_release_path} && bosh -n create release --force && bosh -n upload release")
        rescue Exception => e
          raise e unless e.message =~ /releases/
          puts("Using found release")
        end

        begin
          puts("Checking for stemcell...")
          sh("bosh -n stemcells | tail -1 | grep 'No stemcells'")
          puts("Missing stemcell uploading...")
          stemcell_file_name = LIGHT_STEMCELL_URL.split("/").last
          sh("cd /tmp && rm -f #{stemcell_file_name} && wget '#{LIGHT_STEMCELL_URL}'")
          sh("bosh -n upload stemcell /tmp/#{stemcell_file_name}")
        rescue Exception => e
          raise e unless e.message =~ /stemcells/
          puts("Using found stemcell")
        end

        begin
          puts("Checking for a cf deployment...")
          sh("bosh -n deployments | tail -1 | grep 'No deployments'")

          puts("Missing deployment, creating...")
          BootstrapVmcPlugin::Generator.new("aws_vpc_receipt.yml", "aws_rds_receipt.yml").save
          template_file = File.expand_path(File.join(File.dirname(__FILE__),'..','..','..','templates','cf-aws-template.yml.erb'))

          sh("bosh -n deployment cf-aws.yml")
          sh("bosh -n diff #{template_file}")
        rescue Exception => e
          raise e unless e.message =~ /deployments/
          puts("Using found deployment")
        end

        puts("Running bosh deploy...")
        sh("bosh -n deploy")
      end

      private
      def self.cf_release_path
        '/tmp/cf-release'
      end

      def self.sh(cmd)
        raise "Failed to run: #{cmd}" unless system(cmd)
      end
    end
  end
end
