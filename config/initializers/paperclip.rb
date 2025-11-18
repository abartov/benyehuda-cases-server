# Allow ".foo" as an extension for files with the MIME type "text/plain".
Paperclip.options[:content_type_mappings] = {
  jpg: %w[image/jpeg],
  jpeg: %w[image/jpeg]
}
# Paperclip::DataUriAdapter.register
Paperclip::HttpUrlProxyAdapter.register
