class ScanStorage
  class S3Backend
    class DeleteError < StandardError; end

    def initialize(client = nil)
      @client = client
    end

    def client
      @client ||= Aws::S3::Client.new(region: SiteConstants::S3_REGION,
                                      access_key_id: SiteConstants::AWS_ACCESS_KEY_ID,
                                      secret_access_key: SiteConstants::AWS_SECRET_ACCESS_KEY)
    end

    def bucket
      SiteConstants::S3_BUCKET
    end

    def list(prefix)
      objects = []
      token = nil
      loop do
        resp = client.list_objects_v2(bucket: bucket, prefix: prefix, continuation_token: token)
        objects.concat(resp.contents.map { |o| { key: o.key, size: o.size, last_modified: o.last_modified } })
        break unless resp.is_truncated

        token = resp.next_continuation_token
      end
      objects
    end

    def put(key, io, content_type = nil)
      client.put_object(bucket: bucket, key: key, body: io, content_type: content_type)
    end

    def get(key)
      client.get_object(bucket: bucket, key: key).body.read
    end

    def delete(key)
      client.delete_object(bucket: bucket, key: key)
    end

    def delete_prefix(prefix)
      list(prefix).each_slice(1000) do |batch|
        resp = client.delete_objects(bucket: bucket, delete: { objects: batch.map { |o| { key: o[:key] } } })
        # DeleteObjects succeeds as a request even when individual keys fail.
        next if resp.errors.blank?

        raise DeleteError, resp.errors.map { |e| "#{e.key}: #{e.code} #{e.message}" }.join('; ')
      end
    end

    def url(key, expires_in)
      Aws::S3::Presigner.new(client: client).presigned_url(:get_object, bucket: bucket, key: key,
                                                                       expires_in: expires_in)
    end
  end
end
