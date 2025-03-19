import brioche
import gleam/http
import gleam/option.{type Option}

pub type Client

pub type Acl {
  Private
  PublicRead
  PublicReadWrite
  AwsExecRead
  AuthenticatedRead
  BucketOwnerRead
  BucketOwnerFullControl
  LogDeliveryWrite
}

pub type StorageClass {
  Standard
  DeepArchive
  ExpressOnezone
  Glacier
  GlacierIr
  IntelligentTiering
  OnezoneIa
  Outposts
  ReducedRedundancy
  Snow
  StandardIa
}

pub opaque type Config {
  Config(
    acl: Option(Acl),
    bucket: Option(String),
    region: Option(String),
    access_key_id: Option(String),
    secret_access_key: Option(String),
    session_token: Option(String),
    endpoint: Option(String),
    virtual_hosted_style: Option(Bool),
    part_size: Option(Int),
    queue_size: Option(Int),
    retry: Option(Int),
    mime_type: Option(String),
    storage_class: Option(StorageClass),
  )
}

pub fn config() -> Config {
  Config(
    acl: option.None,
    bucket: option.None,
    region: option.None,
    access_key_id: option.None,
    secret_access_key: option.None,
    session_token: option.None,
    endpoint: option.None,
    virtual_hosted_style: option.None,
    part_size: option.None,
    queue_size: option.None,
    retry: option.None,
    mime_type: option.None,
    storage_class: option.None,
  )
}

pub fn acl(config: Config, acl: Acl) -> Config {
  let acl = option.Some(acl)
  Config(..config, acl:)
}

pub fn bucket(config: Config, bucket: String) -> Config {
  let bucket = option.Some(bucket)
  Config(..config, bucket:)
}

pub fn region(config: Config, region: String) -> Config {
  let region = option.Some(region)
  Config(..config, region:)
}

pub fn access_key_id(config: Config, access_key_id: String) -> Config {
  let access_key_id = option.Some(access_key_id)
  Config(..config, access_key_id:)
}

pub fn secret_access_key(config: Config, secret_access_key: String) -> Config {
  let secret_access_key = option.Some(secret_access_key)
  Config(..config, secret_access_key:)
}

pub fn session_token(config: Config, session_token: String) -> Config {
  let session_token = option.Some(session_token)
  Config(..config, session_token:)
}

pub fn endpoint(config: Config, endpoint: String) -> Config {
  let endpoint = option.Some(endpoint)
  Config(..config, endpoint:)
}

pub fn virtual_hosted_style(
  config: Config,
  virtual_hosted_style: Bool,
) -> Config {
  let virtual_hosted_style = option.Some(virtual_hosted_style)
  Config(..config, virtual_hosted_style:)
}

pub fn part_size(config: Config, part_size: Int) -> Config {
  let part_size = option.Some(part_size)
  Config(..config, part_size:)
}

pub fn queue_size(config: Config, queue_size: Int) -> Config {
  let queue_size = option.Some(queue_size)
  Config(..config, queue_size:)
}

pub fn retry(config: Config, retry: Int) -> Config {
  let retry = option.Some(retry)
  Config(..config, retry:)
}

pub fn mime_type(config: Config, mime_type: String) -> Config {
  let mime_type = option.Some(mime_type)
  Config(..config, mime_type:)
}

pub fn storage_class(config: Config, storage_class: StorageClass) -> Config {
  let storage_class = option.Some(storage_class)
  Config(..config, storage_class:)
}

@external(javascript, "./s3.ffi.mjs", "create")
pub fn client(config: Config) -> Client

@external(javascript, "./s3.ffi.mjs", "file")
pub fn file(client: Client, path: String) -> brioche.File

pub type Presign {
  Presign(
    file: String,
    method: Option(http.Method),
    expires_in: Option(Int),
    acl: Option(Acl),
    mime_type: Option(String),
  )
}

pub fn presign(file: String) -> Presign {
  Presign(
    file:,
    method: option.None,
    expires_in: option.None,
    acl: option.None,
    mime_type: option.None,
  )
}

/// Get, Post, Put, Head, Delete
pub fn presign_method(presign: Presign, method: http.Method) -> Presign {
  Presign(..presign, method: option.Some(method))
}

pub fn presign_expires_in(presign: Presign, expires_in: Int) -> Presign {
  Presign(..presign, expires_in: option.Some(expires_in))
}

pub fn presign_acl(presign: Presign, acl: Acl) -> Presign {
  Presign(..presign, acl: option.Some(acl))
}

pub fn presign_mime_type(presign: Presign, mime_type: String) -> Presign {
  Presign(..presign, mime_type: option.Some(mime_type))
}

@external(javascript, "./s3.ffi.mjs", "presign")
pub fn generate_url(presign: Presign, client: Client) -> String
