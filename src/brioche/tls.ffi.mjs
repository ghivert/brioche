export function generateTLS(tls) {
  if (!tls) return
  return {
    key: tls.key.content,
    cert: tls.cert.content,
    server_name: tls.server_name[0],
    reject_unauthorized: tls.reject_unauthorized[0],
    passphrase: tls.passphrase[0],
    request_cert: tls.request_cert[0],
    ca: tls.ca[0]?.content,
    dh_params_file: tls.dh_params_file[0],
  }
}
