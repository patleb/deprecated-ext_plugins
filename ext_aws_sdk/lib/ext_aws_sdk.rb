module Aws
  autoload :S3, 'ext_aws_sdk/aws_sdk'
  autoload :IAM, 'ext_aws_sdk/aws_sdk'
  autoload :EC2, 'ext_aws_sdk/aws_sdk'
  autoload :RDS, 'ext_aws_sdk/aws_sdk'
  autoload :SES, 'ext_aws_sdk/aws_sdk'
  autoload :Route53, 'ext_aws_sdk/aws_sdk'
  autoload :CloudWatch, 'ext_aws_sdk/aws_sdk'
  autoload :SNS, 'ext_aws_sdk/aws_sdk'
end

module ExtAwsSdk
  # https://gist.github.com/damusix/c12400ee0ccb7e56351619ae2b19a303
  def self.smtp_password(secret)
    signature = "\x02" + OpenSSL::HMAC.digest('sha256', secret, "SendRawEmail")
    Base64.encode64(signature).strip
  end
end
