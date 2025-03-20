//// Bun implements native S3 Client, built directly in the runtime. S3 Client
//// is highly optimized, and rely on JavaScript Core internals for some part
//// of the client.
////
//// Because S3 is built in the runtime, it allows you to use `Bun.File`
//// directly with the S3 protocol, or to consider S3 files as native `Bun.File`.
//// This can help when reading or returning S3 data to your client, or when
//// manipulating files between your servers or S3.
////
//// In case you dislike the API, or you need different features, feel free to
//// use any other S3 client.
////
//// [Bun Documentation](https://bun.sh/docs/api/s3)

import brioche
import gleam/http
import gleam/option.{type Option}

/// Communicating with S3 in Bun can be done in a silent, implicit way. However,
/// Brioche requires you to setup a client to interact with S3. Implicit
/// interaction can still be used with `file`, with the `s3://` protocol
/// as file.
///
/// Instanciating a client should be done with a config. Every config is
/// customisable, but lot of option can be set using environment variables.
/// In case of implicit interaction, environment variables are the only way
/// to configure the connection to S3.
///
/// More details can be found on [`Config`](#Config).
///
/// ```gleam
/// // Using S3 with a client.
/// let client =
///   s3.config()
///   |> s3.bucket("my-bucket")
///   |> s3.client
/// let file = s3.file(client, "my-file.txt")
///
/// // Using S3 implicitely.
/// file.new("s3://my-bucket/my-file.txt")
/// ```
pub type Client

/// > Amazon S3 access control lists (ACLs) enable you to manage access to
/// > buckets and objects. Each bucket and object has an ACL attached to it as
/// > a subresource. It defines which AWS accounts or groups are granted access
/// > and the type of access. When a request is received against a resource,
/// > Amazon S3 checks the corresponding ACL to verify that the requester has
/// > the necessary access permissions.
///
/// [AWS Documentation](https://docs.aws.amazon.com/AmazonS3/latest/userguide/acl-overview.html)
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

/// > Each object in Amazon S3 has a storage class associated with it. By
/// > default, objects in S3 are stored in the S3 Standard storage class,
/// > however Amazon S3 offers a range of other storage classes for the objects
/// > that you store. You choose a class depending on your use case scenario
/// > and performance access requirements. Choosing a storage class designed
/// > for your use case lets you optimize storage costs, performance, and
/// > availability for your objects. All of these storage classes offer high
/// > durability.
///
/// [AWS Documentation](https://docs.aws.amazon.com/AmazonS3/latest/userguide/storage-class-intro.html)
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

/// Configure a connection to S3. Default Config can be created by using
/// [`config`](#config).
pub type Config {
  Config(
    /// Default ACL for files.
    acl: Option(Acl),
    /// S3 Bucket name. Reads `S3_BUCKET` or `AWS_BUCKET` environment
    /// variables if not provided.
    bucket: Option(String),
    /// AWS region. Reads `S3_REGION` or `AWS_REGION` environment
    /// variable if not provided.
    region: Option(String),
    /// Access Key ID for authentication. Reads `S3_ACCESS_KEY_ID` or
    /// `AWS_ACCESS_KEY_ID` environment variable if not provided.
    access_key_id: Option(String),
    /// Secret Key ID for authentication. Reads `S3_SECRET_ACCESS_KEY` or
    /// `AWS_SECRET_ACCESS_KEY` environment variable if not provided.
    secret_access_key: Option(String),
    /// Optional session token for temporary credentials. Reads
    /// `S3_SESSION_TOKEN` or `AWS_SESSION_TOKEN` environment variable
    /// if not provided.
    session_token: Option(String),
    /// S3-compatible service endpoint. Reads `S3_ENDPOINT` or
    /// `AWS_ENDPOINT` environment variable if not provided.
    endpoint: Option(String),
    /// Activate or deactive virtual hosted style. Defaults to `False`.
    virtual_hosted_style: Option(Bool),
    /// The size of each part in multipart uploads (in bytes).
    /// - Minimum: 5 MiB
    /// - Maximum: 5120 MiB
    /// - Default: 5 MiB
    part_size: Option(Int),
    /// Number of parts to upload in parallel for multipart uploads.
    /// - Default: 5
    /// - Maximum: 255
    ///
    /// Increasing this value can improve upload speeds for large files
    /// but will use more memory.
    queue_size: Option(Int),
    /// Number of retry attempts for failed uploads.
    /// - Default: 3
    /// - Maximum: 255
    retry: Option(Int),
    /// The Mime-Type of the file.
    /// Automatically set based on file extension when possible.
    mime_type: Option(String),
    /// By default, Amazon S3 uses the `STANDARD` Storage Class to store
    /// newly created objects.
    storage_class: Option(StorageClass),
  )
}

/// Create a new empty config.
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

/// Set default ACL for the client.
///
/// ```gleam
/// s3.config()
/// |> s3.acl(s3.Public)
/// ```
pub fn acl(config: Config, acl: Acl) -> Config {
  let acl = option.Some(acl)
  Config(..config, acl:)
}

/// Set bucket for the client.
/// Reads `S3_BUCKET` or `AWS_BUCKET` environment variables if not provided.
///
/// ```gleam
/// s3.config()
/// |> s3.bucket("my-bucket")
/// ```
pub fn bucket(config: Config, bucket: String) -> Config {
  let bucket = option.Some(bucket)
  Config(..config, bucket:)
}

/// Set region for the client.
/// Reads `S3_REGION` or `AWS_REGION` environment variable if not provided.
///
/// ```gleam
/// s3.config()
/// |> s3.region("eu-west3")
/// ```
pub fn region(config: Config, region: String) -> Config {
  let region = option.Some(region)
  Config(..config, region:)
}

/// Set access key ID for the client for authentication.
/// Reads `S3_ACCESS_KEY_ID` or `AWS_ACCESS_KEY_ID` environment variable
/// if not provided.
///
/// ```gleam
/// s3.config()
/// |> s3.access_key_id("key")
/// ```
pub fn access_key_id(config: Config, access_key_id: String) -> Config {
  let access_key_id = option.Some(access_key_id)
  Config(..config, access_key_id:)
}

/// Set secret access key for the client for authentication.
/// Reads `S3_SECRET_ACCESS_KEY` or `AWS_SECRET_ACCESS_KEY` environment variable
/// if not provided.
///
/// ```gleam
/// s3.config()
/// |> s3.secret_access_key("key")
/// ```
pub fn secret_access_key(config: Config, secret_access_key: String) -> Config {
  let secret_access_key = option.Some(secret_access_key)
  Config(..config, secret_access_key:)
}

/// Set optional session token for temporary credentials.
/// Reads `S3_SESSION_TOKEN` or `AWS_SESSION_TOKEN` environment variable
/// if not provided.
///
/// ```gleam
/// s3.config()
/// |> s3.secret_access_key("key")
/// ```
pub fn session_token(config: Config, session_token: String) -> Config {
  let session_token = option.Some(session_token)
  Config(..config, session_token:)
}

/// Set endpoint for the client.
/// Reads `S3_ENDPOINT` or `AWS_ENDPOINT` environment variable if not provided.
///
/// ```gleam
/// s3.config()
/// |> s3.endpoint("http://endpoint")
/// ```
pub fn endpoint(config: Config, endpoint: String) -> Config {
  let endpoint = option.Some(endpoint)
  Config(..config, endpoint:)
}

/// Set virtual hosted style for the client.
///
/// ```gleam
/// s3.config()
/// |> s3.virtual_hosted_style(True)
/// ```
pub fn virtual_hosted_style(
  config: Config,
  virtual_hosted_style: Bool,
) -> Config {
  let virtual_hosted_style = option.Some(virtual_hosted_style)
  Config(..config, virtual_hosted_style:)
}

/// Set the size of each part in multipart uploads (in bytes) for the client.
/// - Minimum: 5 MiB
/// - Maximum: 5120 MiB
/// - Default: 5 MiB
///
/// ```gleam
/// s3.config()
/// |> s3.part_size(1024 * 5)
/// ```
pub fn part_size(config: Config, part_size: Int) -> Config {
  let part_size = option.Some(part_size)
  Config(..config, part_size:)
}

/// Set the number of parts to upload in parallel for multipart uploads
/// for the client.
/// - Default: 5
/// - Maximum: 255
///
/// Increasing this value can improve upload speeds for large files
/// but will use more memory.
///
/// ```gleam
/// s3.config()
/// |> s3.queue_size(5)
/// ```
pub fn queue_size(config: Config, queue_size: Int) -> Config {
  let queue_size = option.Some(queue_size)
  Config(..config, queue_size:)
}

/// Set the number of retry attempts for failed uploads for the client.
/// - Default: 3
/// - Maximum: 255
///
/// ```gleam
/// s3.config()
/// |> s3.retry(3)
/// ```
pub fn retry(config: Config, retry: Int) -> Config {
  let retry = option.Some(retry)
  Config(..config, retry:)
}

/// Set the Mime-Type of files for the client.
/// Automatically set based on file extension when possible.
///
/// ```gleam
/// s3.config()
/// |> s3.mime_type("application/json")
/// ```
pub fn mime_type(config: Config, mime_type: String) -> Config {
  let mime_type = option.Some(mime_type)
  Config(..config, mime_type:)
}

/// Set the default Storage Class for created objects. By default,
/// Amazon S3 uses the `STANDARD` Storage Class to store newly created objects.
///
/// ```gleam
/// s3.config()
/// |> s3.storage_class(s3.Standard)
/// ```
pub fn storage_class(config: Config, storage_class: StorageClass) -> Config {
  let storage_class = option.Some(storage_class)
  Config(..config, storage_class:)
}

/// Create a S3 client from a config.
///
/// ```gleam
/// s3.config()
/// |> s3.client
/// ```
@external(javascript, "./s3.ffi.mjs", "create")
pub fn client(config: Config) -> Client

/// Create a file from a S3 client. S3 files are compatible with Bun `File`
/// like files stored directly on file system.
///
/// ```gleam
/// s3.config()
/// |> s3.client
/// |> s3.file("my-file.txt")
/// |> file.read
/// ```
@external(javascript, "./s3.ffi.mjs", "file")
pub fn file(client: Client, path: String) -> brioche.File

/// Configuration for presigning URL.
pub type Presign {
  Presign(
    /// File to presign.
    file: String,
    /// Only Get, Post, Put, Head, Delete methods are supported.
    method: Option(http.Method),
    /// Defines the expiration delay, in seconds.
    expires_in: Option(Int),
    /// Defines the ACL for the file.
    acl: Option(Acl),
    /// Defines the mime-type of a file. It's not needed to be set by default.
    mime_type: Option(String),
  )
}

/// > When your production service needs to let users upload files to your
/// > server, it's often more reliable for the user to upload directly to S3
/// > instead of your server acting as an intermediary.
///
/// > To facilitate this, you can presign URLs for S3 files. This generates a
/// > URL with a signature that allows a user to securely upload that specific
/// > file to S3, without exposing your credentials or granting them unnecessary
/// > access to your bucket.
///
/// > The default behaviour is to generate a GET URL that expires in 24 hours.
/// > Bun attempts to infer the content type from the file extension. If
/// > inference is not possible, it will default to application/octet-stream.
///
/// ```gleam
/// s3.presign("my-file")
/// |> s3.generate_url
/// ```
pub fn presign(file: String) -> Presign {
  Presign(
    file:,
    method: option.None,
    expires_in: option.None,
    acl: option.None,
    mime_type: option.None,
  )
}

/// Only Get, Post, Put, Head, Delete methods are supported.
///
/// ```gleam
/// s3.presign("my-file")
/// |> s3.presign_method(http.Get)
/// ```
pub fn presign_method(presign: Presign, method: http.Method) -> Presign {
  Presign(..presign, method: option.Some(method))
}

/// Defines the expiration delay, in seconds.
///
/// ```gleam
/// s3.presign("my-file")
/// |> s3.presign_expires_in(3600)
/// ```
pub fn presign_expires_in(presign: Presign, expires_in: Int) -> Presign {
  Presign(..presign, expires_in: option.Some(expires_in))
}

/// Defines the ACL for the file.
///
/// ```gleam
/// s3.presign("my-file")
/// |> s3.presign_acl(s3.Public)
/// ```
pub fn presign_acl(presign: Presign, acl: Acl) -> Presign {
  Presign(..presign, acl: option.Some(acl))
}

/// Defines the mime-type of a file. It's not needed to be set by default.
///
/// ```gleam
/// s3.presign("my-file")
/// |> s3.presign_mime_type("application/json")
/// ```
pub fn presign_mime_type(presign: Presign, mime_type: String) -> Presign {
  Presign(..presign, mime_type: option.Some(mime_type))
}

/// Generate presigned URL for `Presign` configuration.
///
/// ```gleam
/// s3.presign("my-file")
/// |> s3.generate_url
/// ```
@external(javascript, "./s3.ffi.mjs", "presign")
pub fn generate_url(presign: Presign, client: Client) -> String
