import brioche as bun
import gleam/option.{type Option, None, Some}

pub type Tls {
  Tls(
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
  File(content: bun.File)
}

pub fn new(key key: Data, cert cert: Data) -> Tls {
  Tls(
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

pub fn passphrase(tls: Tls, passphrase: String) -> Tls {
  let passphrase = Some(passphrase)
  Tls(..tls, passphrase:)
}

pub fn server_name(tls: Tls, server_name: String) -> Tls {
  let server_name = Some(server_name)
  Tls(..tls, server_name:)
}

pub fn reject_unauthorized(tls: Tls, reject_unauthorized: Bool) -> Tls {
  let reject_unauthorized = Some(reject_unauthorized)
  Tls(..tls, reject_unauthorized:)
}

pub fn request_cert(tls: Tls, request_cert: Bool) -> Tls {
  let request_cert = Some(request_cert)
  Tls(..tls, request_cert:)
}

pub fn ca(tls: Tls, ca: Data) -> Tls {
  let ca = Some(ca)
  Tls(..tls, ca:)
}

pub fn dh_params_file(tls: Tls, dh_params_file: String) -> Tls {
  let dh_params_file = Some(dh_params_file)
  Tls(..tls, dh_params_file:)
}
