require "erb"
require "vmc"
require "common/version"
require "bootstrap-vmc-plugin/generator"
require "bootstrap-vmc-plugin/plugin"
require "bootstrap-vmc-plugin/director_check"
require "bootstrap-vmc-plugin/infrastructure/aws"
require 'net/http'

require 'cli/config'  # for load_yaml_file
require 'cli/errors'  # for load_yaml_file
require 'cli/yaml_helper'  # for load_yaml_file
require 'cli/core_ext'  # for load_yaml_file
require 'syck'
