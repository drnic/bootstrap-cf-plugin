source 'http://rubygems.org'


git "git://github.com/cloudfoundry/bosh" do
  gem "bosh_aws_bootstrap"
end

gemspec

group :test do
  gem "rake"
  gem "rspec"
  gem "vmc", :git => "git://github.com/cloudfoundry/vmc.git"
  gem "fakefs"
  gem "rr"
end
