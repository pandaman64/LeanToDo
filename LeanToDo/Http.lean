-- A minimal implementation of HTTP 1.1 server

import Std.Internal.Async

open Std.Internal.IO Async

namespace LeanToDo.Http

inductive StatusCode where
  | ok
  | not_found
  | internal_server_error

def StatusCode.asNat (code : StatusCode) : Nat :=
  match code with
  | .ok => 200
  | .not_found => 404
  | .internal_server_error => 500

def StatusCode.asString (code : StatusCode) : String :=
  match code with
  | .ok => "OK"
  | .not_found => "Not Found"
  | .internal_server_error => "Internal Server Error"

structure Request where
  method : String
  path : String
  body : String

structure Response where
  code : StatusCode
  contentType : String
  body : String

def Response.ofHtml (html : String) (code : StatusCode := .ok) : Response := {
  code := code,
  contentType := "text/html",
  body := html
}

def readRequest (client : TCP.Socket.Client) : Async Request := do
  let mut buffer := ""
  let mut headersDone := false
  while !headersDone do
    let chunk ← client.recv? 8192
    match chunk.bind String.fromUTF8? with
    | .none => throw (.userError "Failed to read request")
    | .some str =>
      buffer := buffer ++ str
      match (buffer.split "\r\n\r\n").toList with
      | _ :: _ :: _ => headersDone := true
      | _ => pure ()

  let parts := (buffer.split "\r\n\r\n").toList.map (fun s => s.toString)
  let header :=
    match parts with
    | [] => ""
    | h :: _ => h
  let bodyStart :=
    match parts with
    | [] => ""
    | _ :: rest => String.intercalate "\r\n\r\n" rest

  IO.eprintln s!"request headers: {String.quote header}"
  IO.eprintln s!"request body start: {String.quote bodyStart}"
  let mut method : Option String := .none
  let mut path : Option String := .none
  let mut contentLength : Option Nat := .none

  for lineSlice in header.split "\r\n" do
    let line := lineSlice.toString
    if method.isNone then
      let values := line.split " " |>.toArray
      method := values[0]!.copy
      path := values[1]!.copy
    else if line.toLower.startsWith "content-length:" then
      let value := line.toLower.drop "content-length:".length |>.trimAscii
      match value.toNat? with
      | .some n => contentLength := .some n
      | .none => throw (.userError "Invalid Content-Length")

  let mut body := ""
  match contentLength with
  | .none => body := ""
  | .some len =>
    body := bodyStart
    let mut remaining := if body.length >= len then 0 else len - body.length
    while remaining > 0 do
      let chunk ← client.recv? 8192
      match chunk.bind String.fromUTF8? with
      | .none => throw (.userError "Failed to read request body")
      | .some str =>
        body := body ++ str
        remaining := if body.length >= len then 0 else len - body.length
    let rawPos : String.Pos.Raw := ⟨len⟩
    if h : rawPos.IsValid body then
      body := body.sliceTo ⟨rawPos, h⟩ |>.toString
    else
      throw (.userError "Invalid Content-Length")

  return {
    method := method.get!,
    path := path.get!,
    body := body,
  }

def writeResponse (client : TCP.Socket.Client) (response : Response) : Async Unit := do
  let response :=
    s!"HTTP/1.1 {response.code.asNat} {response.code.asString}\r\n" ++
    s!"Content-Type: {response.contentType}\r\n" ++
    s!"Content-Length: {response.body.length}\r\n\r\n{response.body}"
  client.send response.toUTF8

def serve (server : TCP.Socket.Server) (handler : Request → Async Response) : Async Unit := do
  while true do
    let client ← server.accept
    let request ← readRequest client
    let response ← handler request
    writeResponse client response

end LeanToDo.Http
