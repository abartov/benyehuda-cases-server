Paperclip.options[:content_type_mappings] = {
  jpg: %w[image/jpeg],
  jpeg: %w[image/jpeg]
}
Paperclip::Attachment.default_options[:storage] = :s3
Paperclip::Attachment.default_options[:s3_protocol] = :https
Paperclip::Attachment.default_options[:s3_region] = SiteConstants::S3_REGION
Paperclip::Attachment.default_options[:bucket] = SiteConstants::S3_BUCKET
Paperclip::Attachment.default_options[:s3_credentials] = {
  access_key_id: SiteConstants::AWS_ACCESS_KEY_ID,
  secret_access_key: SiteConstants::AWS_SECRET_ACCESS_KEY
}
# Paperclip::DataUriAdapter.register
Paperclip::HttpUrlProxyAdapter.register
