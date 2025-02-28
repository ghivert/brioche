import brioche
import gleam/option.{type Option, None, Some}

pub type TLS {
  TLS(
    key: Data,
    cert: Data,
    server_name: Option(String),
    reject_unauthorized: Option(Bool),
    passphrase: Option(String),
    request_cert: Option(Bool),
    ca: Option(Data),
    dh_params_file: Option(String),
  )
}

pub type Data {
  Text(content: String)
  Bytes(content: BitArray)
  File(content: brioche.File)
}

pub fn new(key: Data, cert: Data) -> TLS {
  TLS(
    key:,
    cert:,
    server_name: None,
    reject_unauthorized: None,
    passphrase: None,
    request_cert: None,
    ca: None,
    dh_params_file: None,
  )
}

pub fn passphrase(tls: TLS, passphrase: String) -> TLS {
  let passphrase = Some(passphrase)
  TLS(..tls, passphrase:)
}

pub fn server_name(tls: TLS, server_name: String) -> TLS {
  let server_name = Some(server_name)
  TLS(..tls, server_name:)
}

pub fn reject_unauthorized(tls: TLS, reject_unauthorized: Bool) -> TLS {
  let reject_unauthorized = Some(reject_unauthorized)
  TLS(..tls, reject_unauthorized:)
}

pub fn request_cert(tls: TLS, request_cert: Bool) -> TLS {
  let request_cert = Some(request_cert)
  TLS(..tls, request_cert:)
}

pub fn ca(tls: TLS, ca: Data) -> TLS {
  let ca = Some(ca)
  TLS(..tls, ca:)
}

pub fn dh_params_file(tls: TLS, dh_params_file: String) -> TLS {
  let dh_params_file = Some(dh_params_file)
  TLS(..tls, dh_params_file:)
}
