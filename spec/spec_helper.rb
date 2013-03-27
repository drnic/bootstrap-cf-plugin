require "bootstrap-cf-plugin"
require "cfoundry/test_support"
require "cf/test_support"

def asset(filename)
  File.expand_path("../assets/#{filename}", __FILE__)
end

def stub_invoke(*args)
  any_instance_of described_class do |cli|
    stub(cli).invoke *args
  end
end

RSpec.configure do |c|
  c.include Fake::FakeMethods
  c.include V1Fake::FakeMethods
  c.include ConsoleAppSpeckerMatchers

  c.mock_with :rr

  c.include FakeHomeDir
  c.include CommandHelper
  c.include InteractHelper
  c.include ConfigHelper
end
