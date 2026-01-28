import SQLite
import Verso
import Std.Internal.Async
import Std.Data.HashMap

import LeanToDo
import LeanToDo.Pages.Index
import LeanToDo.Pages.Project

open Std.Internal.IO Async
open Std (HashMap)
open System.Uri.UriEscape (decodeUri)
open Verso.Output (Html)
open Verso.Output.Html

open LeanToDo Model
open LeanToDo.Http

def parseFormData (s : String) : HashMap String String :=
  HashMap.ofArray $
    s.split "&"
    |>.filterMap (fun kv =>
      match kv.split "=" |>.toArray with
      | #[k, v] => some (decodeUri k.copy, decodeUri v.copy)
      | #[k]    => some (decodeUri k.copy, "")
      | _      => none)
    |>.toArray

def route (app : App) (request : Request) : IO Response := do
  let segments :=
    (request.path.splitOn "/").filter (fun segment => segment != "") |>.toArray
  match request.method, segments with
  | "GET", #[] =>
      let html ← LeanToDo.Pages.Index.render app
      return Response.ofHtml html.asString
  | "GET", #["project", idString] =>
      match String.toInt? idString with
      | .some id =>
          let html ← LeanToDo.Pages.Project.render (Int64.ofInt id) app
          return Response.ofHtml html.asString
      | .none => return Response.ofHtml "Not Found" .not_found
  | "POST", #["todos", idString] =>
      match String.toInt? idString with
      | .some id =>
          let formData := parseFormData request.body
          let .some projectId := formData.get? "projectId" >>= String.toInt?
            | throw <| IO.userError "Invalid projectId"
          let .some title := formData.get? "title"
            | throw <| IO.userError "Invalid title"
          let .some completed := formData.get? "completed"
            | throw <| IO.userError "Invalid completed"
          let todo : Todo := {
            id := Int64.ofInt id,
            projectId := Int64.ofInt projectId,
            title := title,
            completed := completed == "true",
          }
          let .some _ ← getTodo todo.id app.db
            | return Response.ofHtml "Not Found" .not_found
          updateTodo todo app.db
          let html := LeanToDo.Pages.Project.renderTodo todo
          return Response.ofHtml html.asString
      | .none => return Response.ofHtml "Not Found" .not_found
  | _, _ => return Response.ofHtml "Not Found" .not_found

def runServer (app : App) : IO Unit := do
  let server ← TCP.Socket.Server.mk
  server.bind (Std.Net.SocketAddressV4.mk (.ofParts 127 0 0 1) 8080)
  server.listen 128
  IO.println "Server is running on port 8080"
  let serverTask := LeanToDo.Http.serve server fun request => do
    route app request
  (← serverTask.toIO).block

def prepareDatabase (app : App) : IO Unit := do
  let db := app.db
  db.exec "PRAGMA journal_mode=WAL"
  db.exec "PRAGMA synchronous=NORMAL"
  db.exec "PRAGMA busy_timeout=5000"
  db.exec "PRAGMA foreign_keys=ON"
  db.exec "DROP TABLE IF EXISTS todos"
  db.exec "DROP TABLE IF EXISTS projects"
  db.exec "CREATE TABLE IF NOT EXISTS projects (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)"
  db.exec "CREATE TABLE IF NOT EXISTS todos (id INTEGER PRIMARY KEY AUTOINCREMENT, project_id INTEGER, title TEXT, completed BOOLEAN, FOREIGN KEY(project_id) REFERENCES projects(id))"

  let .some project ← createProject { name := "LeanToDo development" } db
    | throw <| IO.userError "Failed to create project"
  let projectId := project.id

  let newTodos : Array NewTodo := #[
    { projectId, title := "Set up the database", completed := true },
    { projectId, title := "Set up the server", completed := true },
    { projectId, title := "Incorporate HTMX", completed := false },
    { projectId, title := "Incorporate Tailwind CSS", completed := false },
    { projectId, title := "Scaffold the HTML components", completed := false },
    { projectId, title := "Create a new todo", completed := false },
    { projectId, title := "Edit a todo", completed := false },
    { projectId, title := "Delete a todo", completed := false },
    { projectId, title := "Mark a todo as completed", completed := false },
    { projectId, title := "Mark a todo as not completed", completed := false },
    { projectId, title := "Delete a todo", completed := false },
  ]
  for todo in newTodos do
    let .some todo ← createTodo todo db | continue
    IO.println s!"Created todo: {todo.id} {todo.title} {todo.completed}"

def main : IO Unit := do
  let app : App := { db := ← SQLite.open "test.db" }
  prepareDatabase app
  runServer app
