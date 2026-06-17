require 'deployment_helpers'

unless DeploymentHelpers.assets_compilation?
  Paperclip.options[:content_type_mappings] = {
    jpg: %w[image/jpeg],
    jpeg: %w[image/jpeg]
  }
  Paperclip::Attachment.default_options[:storage] = :s3
  Paperclip::Attachment.default_options[:s3_protocol] = :https
  Paperclip::Attachment.default_options[:s3_region] = ENV.fetch('S3_REGION')
  Paperclip::Attachment.default_options[:bucket] = ENV.fetch('S3_BUCKET')
  Paperclip::Attachment.default_options[:s3_credentials] = {
    access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID'),
    secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY')
  }
  # Paperclip::DataUriAdapter.register
  Paperclip::HttpUrlProxyAdapter.register
end
