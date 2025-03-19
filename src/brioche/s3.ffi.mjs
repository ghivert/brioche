import * as bun from 'bun'
import * as $s3 from './s3.mjs'
import * as $http from '../../gleam_http/gleam/http.mjs'

export function create(options) {
  return new bun.S3Client({
    acl: convertAcl(options.acl[0]),
    bucket: options.bucket[0],
    region: options.region[0],
    accessKeyId: options.access_key_id[0],
    secretAccessKey: options.secret_access_key[0],
    sessionToken: options.session_token[0],
    endpoint: options.endpoint[0],
    virtualHostedStyle: options.virtual_hosted_style[0],
    partSize: options.part_size[0],
    queueSize: options.queue_size[0],
    retry: options.retry[0],
    contentType: options.content_type[0],
    storageClass: convertStorageClass(options.storage_class[0]),
  })
}

export function file(client, path) {
  return client.file(path)
}

export function presign(options, client) {
  return client.presign(options.file, {
    method: convertMethod(options.method[0]),
    expiresIn: options.expires_in[0],
    acl: convertAcl(options.acl[0]),
    type: options.mime_type[0],
  })
}

function convertAcl(acl) {
  if (!acl) return
  if (acl instanceof $s3.Private) return 'private'
  if (acl instanceof $s3.PublicRead) return 'public-read'
  if (acl instanceof $s3.PublicReadWrite) return 'public-read-write'
  if (acl instanceof $s3.AwsExecRead) return 'aws-exec-read'
  if (acl instanceof $s3.AuthenticatedRead) return 'authenticated-read'
  if (acl instanceof $s3.BucketOwnerRead) return 'bucket-owner-read'
  if (acl instanceof $s3.BucketOwnerFullControl)
    return 'bucket-owner-full-control'
  if (acl instanceof $s3.LogDeliveryWrite) return 'log-delivery-write'
}

function convertStorageClass(storageClass) {
  if (!storageClass) return
  if (storageClass instanceof $s3.Standard) return 'STANDARD'
  if (storageClass instanceof $s3.DeepArchive) return 'DEEP_ARCHIVE'
  if (storageClass instanceof $s3.ExpressOnezone) return 'EXPRESS_ONEZONE'
  if (storageClass instanceof $s3.Glacier) return 'GLACIER'
  if (storageClass instanceof $s3.GlacierIr) return 'GLACIER_IR'
  if (storageClass instanceof $s3.IntelligentTiering)
    return 'INTELLIGENT_TIERING'
  if (storageClass instanceof $s3.OnezoneIa) return 'ONEZONE_IA'
  if (storageClass instanceof $s3.Outposts) return 'OUTPOSTS'
  if (storageClass instanceof $s3.ReducedRedundancy) return 'REDUCED_REDUNDANCY'
  if (storageClass instanceof $s3.Snow) return 'SNOW'
  if (storageClass instanceof $s3.StandardIa) return 'STANDARD_IA'
}

function convertMethod(method) {
  if (method instanceof $http.Get) return 'GET'
  if (method instanceof $http.Post) return 'POST'
  if (method instanceof $http.Put) return 'PUT'
  if (method instanceof $http.Head) return 'HEAD'
  if (method instanceof $http.Delete) return 'DELETE'
}
