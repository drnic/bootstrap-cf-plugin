require "bootstrap-vmc-plugin"

def asset(filename)
  File.expand_path("../assets/#{filename}", __FILE__)
end
