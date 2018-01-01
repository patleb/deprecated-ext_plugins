$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require_relative "./../version"
version = ExtPlugins::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ext_aws_sdk"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/ext_aws_sdk"
  s.summary     = "ExtAwsSdk"
  s.description = "ExtAwsSdk"
  s.license     = "MIT"

  s.files = Dir["lib/**/*", "MIT-LICENSE", "README.md"]

  s.required_ruby_version = ">= #{File.read(File.expand_path("../.ruby-version", __dir__)).strip}"

  s.add_dependency 'aws-sdk-s3'
  s.add_dependency 'aws-sdk-iam'
  s.add_dependency 'aws-sdk-ec2'
  s.add_dependency 'aws-sdk-rds'
  s.add_dependency 'aws-sdk-ses'
  s.add_dependency 'aws-sdk-route53'
  s.add_dependency 'aws-sdk-cloudwatch'
  s.add_dependency 'aws-sdk-sns'
end
