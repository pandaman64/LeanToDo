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

def setupConnection (db : SQLite) : IO Unit := do
  db.exec "PRAGMA journal_mode=WAL"
  db.exec "PRAGMA synchronous=NORMAL"
  db.exec "PRAGMA busy_timeout=5000"
  db.exec "PRAGMA foreign_keys=ON"
  db.exec "CREATE TABLE IF NOT EXISTS projects (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)"
  db.exec "CREATE TABLE IF NOT EXISTS todos (id INTEGER PRIMARY KEY AUTOINCREMENT, project_id INTEGER, title TEXT, completed BOOLEAN, FOREIGN KEY(project_id) REFERENCES projects(id))"

def seedDatabase (db : SQLite) : IO Unit := do
  db.exec "DROP TABLE IF EXISTS todos"
  db.exec "DROP TABLE IF EXISTS projects"
  db.exec "CREATE TABLE IF NOT EXISTS projects (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)"
  db.exec "CREATE TABLE IF NOT EXISTS todos (id INTEGER PRIMARY KEY AUTOINCREMENT, project_id INTEGER, title TEXT, completed BOOLEAN, FOREIGN KEY(project_id) REFERENCES projects(id))"

  let .some project ← createProject { name := "LeanToDo development" } db
    | throw <| IO.userError "Failed to create project"
  let projectId := project.id

  let newTodos : Array NewTodo := #[
    { projectId, title := "Set up database", completed := true },
    { projectId, title := "Set up HTTP server", completed := true },
    { projectId, title := "Add HTMX and Tailwind CSS", completed := false },
    { projectId, title := "Create a new todo", completed := false },
    { projectId, title := "Mark/unmark a todo as completed", completed := false },
    { projectId, title := "Delete a todo", completed := false },
  ]
  for todo in newTodos do
    let .some _ ← createTodo todo db | continue

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
  | "GET", #["project", "new"] =>
      let html := LeanToDo.Pages.Index.renderNewProjectForm true
      return Response.ofHtml html.asString
  | "GET", #["project", idString, "new"] =>
      match String.toInt? idString with
      | .some id =>
          let html := LeanToDo.Pages.Project.renderNewTodoForm id.toInt64 true
          return Response.ofHtml html.asString
      | .none => return Response.ofHtml "Not Found" .not_found
  | "GET", #["project", idString] =>
      match String.toInt? idString with
      | .some id =>
          let html ← LeanToDo.Pages.Project.render (Int64.ofInt id) app
          return Response.ofHtml html.asString
      | .none => return Response.ofHtml "Not Found" .not_found
  | "POST", #["project", "new"] =>
      let formData := parseFormData request.body
      let .some name := formData.get? "name"
        | throw <| IO.userError "Invalid name"
      let newProject : NewProject := { name := name }
      let .some _ ← createProject newProject app.db
        | throw <| IO.userError "Failed to create project"
      let html ← LeanToDo.Pages.Index.render app
      return Response.ofHtml html.asString
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
  | "POST", #["project", idString, "new"] =>
      match String.toInt? idString with
      | .some projectId =>
          let formData := parseFormData request.body
          let .some title := formData.get? "title"
            | throw <| IO.userError "Invalid title"
          let newTodo : NewTodo := {
            projectId := Int64.ofInt projectId
            title := title
            completed := false
          }
          let .some _ ← createTodo newTodo app.db
            | throw <| IO.userError "Failed to create todo"
          let html ← LeanToDo.Pages.Project.render (Int64.ofInt projectId) app
          return Response.ofHtml html.asString
      | .none => return Response.ofHtml "Not Found" .not_found
  | "POST", #["seed"] =>
      seedDatabase app.db
      return Response.ofHtml "" .ok
  | "DELETE", #["todos", idString] =>
      match String.toInt? idString with
      | .some id =>
          let .some todo ← getTodo (Int64.ofInt id) app.db
            | return Response.ofHtml "Not Found" .not_found
          deleteTodo todo.id app.db
          return Response.ofHtml "" .ok
      | .none => return Response.ofHtml "Not Found" .not_found
  | _, _ => return Response.ofHtml "Not Found" .not_found

def runServer (app : App) : IO Unit := do
  let server ← TCP.Socket.Server.mk
  server.bind (Std.Net.SocketAddressV4.mk (.ofParts 0 0 0 0) 8080)
  server.listen 128
  IO.println "Server is running on port 8080"
  let serverTask := LeanToDo.Http.serve server fun request => do
    try
      route app request
    catch e =>
      IO.eprintln s!"Error: {e}"
      return Response.ofHtml "Internal Server Error" .internal_server_error
  (← serverTask.toIO).block

def main : IO Unit := do
  let app : App := { db := ← SQLite.open "test.db" }
  setupConnection app.db
  runServer app
