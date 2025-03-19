import * as $server from './server.mjs'
import * as $websocket from './websocket.mjs'
import * as $gleam from '../gleam.mjs'
import * as $request from '../../gleam_http/gleam/http/request.mjs'
import * as $http from '../../gleam_http/gleam/http.mjs'
import * as $option from '../../gleam_stdlib/gleam/option.mjs'
import { generateTLS } from './tls.ffi.mjs'

export function escapeHTML(content) {
  return Bun.escapeHTML(content)
}

export function serve(options) {
  const opts = convertOptions(options)
  const server = Bun.serve(opts)
  return server
}

export function reload(server, options) {
  const opts = convertOptions(options)
  server.reload(opts)
  return server
}

export function ref(server) {
  server.ref()
  return server
}

export function unref(server) {
  server.unref()
  return server
}

export function timeout(server, request, timeout) {
  server.timeout(request.body, timeout)
  return request
}

export function requestIp(server, request) {
  const ip = server.requestIP(request.body)
  if (!ip) return new $option.None()
  const address =
    ip.family === 'IPv4'
      ? new $server.IPv4(ip.address)
      : new $server.IPv6(ip.address)
  const socketAddress = new $server.SocketAddress(ip.port, address)
  return new $option.Some(socketAddress)
}

export function upgrade(server, request, headers, context, next) {
  const headers_ = new Headers()
  for (const [header, value] of headers) headers_.append(header, value)
  const options = { headers: headers_, data: context }
  if (server.upgrade(request.body, options)) return undefined
  return next()
}

export function publish(server, topic, data) {
  const dat = data.rawBuffer !== undefined ? data.rawBuffer : data
  const result = server.publish(topic, dat)
  if (result === 0) return new $websocket.MessageDropped()
  if (result === -1) return new $websocket.MessageBackpressured()
  return new $websocket.MessageSent(result)
}

export const stop = (server, force) => server.stop(force)
export const getPort = server => server.port
export const getDevelopment = server => server.development
export const getHostname = server => server.hostname
export const getId = server => server.id
export const getPendingRequests = server => server.pendingRequests
export const getPendingWebsockets = server => server.pendingWebSockets
export const getUrl = server => server.url.toString()
export const subscriberCount = (server, topic) => server.subscriberCount(topic)
export const data = ws => ws.data
export const readyState = ws => ws.readyState
export const remoteAddress = ws => ws.remoteAddress
export const wsClose = (ws, code, reason) => ws.close(code, reason)
export const wsTerminate = ws => ws.terminate()
export const wsPing = ws => ws.ping()
export const wsPong = ws => ws.pong()
export const wsSubscribe = (ws, topic) => ws.subscribe(topic)
export const wsUnsubscribe = (ws, topic) => ws.unsubscribe(topic)
export const wsIsSubscribed = (ws, topic) => ws.isSubscribed(topic)
export const wsCork = (ws, callback) => ws.cork(callback)

export function wsSend(ws, message) {
  const message_ = message.rawBuffer !== undefined ? message.rawBuffer : message
  const result = ws.send(message_)
  if (result === 0) return new $websocket.MessageDropped()
  if (result === -1) return new $websocket.MessageBackpressured()
  return new $websocket.MessageSent(result)
}

function convertOptions(options) {
  return {
    port: options.port[0],
    hostname: options.hostname[0],
    static: generateStatic(options),
    tls: generateTLS(options.tls[0]),
    websocket: generateWebsocket(options),
    async fetch(request, server) {
      const req = toHttpRequest(request)
      const response = await options.fetch(req, server)
      if (response === undefined) return response
      return generateResponse(response)
    },
  }
}

function toHttpRequest(request) {
  const url = new URL(request.url)
  const port = parseInt(url.port)
  return new $request.Request(
    toHttpMethod(request.method),
    $gleam.toList([...request.headers]),
    request,
    url.protocol === 'http:' ? new $http.Http() : new $http.Https(),
    url.hostname,
    isNaN(port) ? new $option.None() : new $option.Some(port),
    url.pathname,
    url.search ? new $option.Some(url.search) : new $option.None()
  )
}

function toHttpMethod(method) {
  switch (method) {
    case 'GET':
      return new $http.Get()
    case 'POST':
      return new $http.Post()
    case 'HEAD':
      return new $http.Head()
    case 'PUT':
      return new $http.Put()
    case 'DELETE':
      return new $http.Delete()
    case 'TRACE':
      return new $http.Trace()
    case 'CONNECT':
      return new $http.Connect()
    case 'OPTIONS':
      return new $http.Options()
    case 'PATCH':
      return new $http.Patch()
    default:
      return new $http.Other(method)
  }
}

function generateResponse(res) {
  const status = res.status
  const headers = new Headers()
  for (const [header, value] of res.headers) headers.append(header, value)
  const options = { status, headers }
  if ('text' in res.body) return new Response(res.body.text, options)
  if ('json' in res.body) return Response.json(res.body.json, options)
  if ('bytes' in res.body) return new Response(res.body.bytes, options)
  if ('file' in res.body) return new Response(res.body.file, options)
  return new Response(null, options)
}

function generateStatic(options) {
  const static_routes = options.static_routes[0]
  if (!static_routes) return
  const routes = static_routes.toArray()
  const bunRoutes = routes.map(([key, value]) => [key, generateResponse(value)])
  return Object.fromEntries(bunRoutes)
}

function generateWebsocket(options) {
  const websocket = options.websocket[0]
  if (!websocket) return
  const messageHandler =
    websocket.on_text_message[0] || websocket.on_bytes_message[0]
  return {
    message: !messageHandler ? undefined : generateMessageHandler(websocket),
    open: websocket.on_open[0],
    close: websocket.on_close[0],
    drain: websocket.on_drain[0],
    maxPayloadLength: websocket.max_payload_length[0],
    backpressureLimit: websocket.backpressure_limit[0],
    closeOnBackpressureLimit: websocket.close_on_backpressure_limit[0],
    idleTimeout: websocket.idle_timeout[0],
    publishToSelf: websocket.publish_to_self[0],
    sendPings: websocket.send_pings[0],
  }
}

function generateMessageHandler(websocket) {
  return function (ws, message) {
    if (typeof message === 'string')
      return websocket.on_text_message[0]?.(ws, message)
    if (message instanceof Uint8Array) {
      const data = $gleam.toBitArray(message)
      return websocket.on_bytes_message[0]?.(ws, data)
    }
  }
}
