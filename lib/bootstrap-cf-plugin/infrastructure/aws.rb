module BootstrapCfPlugin
  module Infrastructure
    class Aws
      DEFAULT_LIGHT_STEMCELL_URL = "http://bosh-jenkins-artifacts.s3.amazonaws.com/last_successful_bosh-stemcell_light.tgz"

      def self.bootstrap(template_file = nil)
        upload_stemcell
        deploy_release("cf-release", "cf-aws.yml", nil, template_file)
        deploy_release("cf-services-release", "cf-services-aws.yml", "cf-aws.yml", template_file)

        puts "INFO: bootstrap complete"
        sh("bosh -n status")
      end

      def self.deploy_release(release_name, manifest_name, upstream_manifest, template_file)
        cf_release_path = cf_release_path(release_name)
        git_url = "http://github.com/cloudfoundry/#{release_name}"

        puts("Creating release #{release_name}")
        puts "git clone #{git_url} #{cf_release_path}"

        sh("git clone #{git_url} #{cf_release_path}") unless Dir.exist?(cf_release_path)
        dev_config_path = File.join(cf_release_path, "config", "dev.yml")
        unless File.exists?(dev_config_path)
          File.open(dev_config_path, "w") { |f| f.write("---\ndev_name: #{release_name}") }
        end
        sh("cd #{cf_release_path} && ./update")
        sh("cd #{cf_release_path} && bosh -n create release --force && bosh -n upload release")

        puts("Creating deployment manifest #{manifest_name}")
        generate_stub(manifest_name, upstream_manifest)
        template_file ||= File.join(cf_release_path, 'templates', 'cf-aws-template.yml.erb')

        sh("bosh -n deployment #{manifest_name}")
        sh("bosh -n diff #{template_file}")

        puts("Running bosh deploy...")
        sh("bosh -n deploy")
        begin
          puts("Checking for release...")
          sh("bosh -n releases | grep -v 'bosh-release'")
          puts("Missing release, creating...")
          sh("git clone -b release-candidate http://github.com/cloudfoundry/cf-release #{cf_release_path}") unless Dir.exist?(cf_release_path)
          sh("cd #{cf_release_path} && git submodule foreach --recursive git submodule sync && git submodule update --init --recursive")
          sh("cd #{cf_release_path} && bosh -n create release --force && bosh -n upload release")
        rescue Exception => e
          raise e unless e.message =~ /releases/
          puts("Using found release")
        end
      end

      def self.upload_stemcell
        begin
          unless ENV.has_key? "BOSH_OVERRIDE_LIGHT_STEMCELL_URL"
            puts("Checking for stemcell...")
            sh("bosh -n stemcells | tail -1 | grep 'No stemcells'")
            puts("Missing stemcell uploading...")
          end
          stemcell_file_name = light_stemcell_url.split("/").last
          sh("cd /tmp && rm -f #{stemcell_file_name} && wget '#{light_stemcell_url}' --no-check-certificate")
          sh("bosh -n upload stemcell /tmp/#{stemcell_file_name}")
        rescue Exception => e
          raise e unless e.message =~ /stemcells/
          puts("Using found stemcell")
        end
      end

      def self.generate_stub(manifest_name, upstream_manifest)
        generator.save(manifest_name, upstream_manifest)
      end

      private
      def self.cf_release_path(release_name)
        File.join(Dir.tmpdir, release_name)
      end

      def self.sh(cmd)
        raise "Failed to run: #{cmd}" unless system(cmd)
      end

      def self.light_stemcell_url
        ENV["BOSH_OVERRIDE_LIGHT_STEMCELL_URL"] || DEFAULT_LIGHT_STEMCELL_URL
      end

      def self.generator
        @generator ||= BootstrapCfPlugin::Generator.new("aws_vpc_receipt.yml", "aws_rds_receipt.yml")
      end
    end
  end
end
