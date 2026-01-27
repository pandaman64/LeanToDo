-- A minimal implementation of HTTP 1.1 server

import Std.Internal.Async

open Std.Internal.IO Async

namespace LeanToDo.Http

inductive StatusCode where
  | ok
  | not_found

def StatusCode.asNat (code : StatusCode) : Nat :=
  match code with
  | .ok => 200
  | .not_found => 404

def StatusCode.asString (code : StatusCode) : String :=
  match code with
  | .ok => "OK"
  | .not_found => "Not Found"

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

def Response.ofJson (json : String) (code : StatusCode := .ok) : Response := {
  code := code,
  contentType := "application/json",
  body := json
}

def readRequest (client : TCP.Socket.Client) : Async Request := do
  let message ← client.recv? 8096
  match message.bind String.fromUTF8? with
  | .none => throw (.userError "Failed to read request")
  | .some request =>
    let mut method : Option String := .none
    let mut path : Option String := .none
    let mut body : Option String := .none
    let mut parsedHeaders := false

    for line in request.split "\r\n" do
      if parsedHeaders then
        body := line.copy
        break
      else if method.isNone then
        let values := line.split " " |>.toArray
        method := values[0]!.copy
        path := values[1]!.copy
      else if line == "" then
        parsedHeaders := true

    return {
      method := method.get!,
      path := path.get!,
      body := body.getD "",
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
