import SQLite
import Verso
import Std.Internal.Async

import LeanToDo

open Std.Internal.IO Async
open Verso.Output (Html)
open Verso.Output.Html

open LeanToDo Model

def runServer (app : App) : IO Unit := do
  let server ← TCP.Socket.Server.mk
  server.bind (Std.Net.SocketAddressV4.mk (.ofParts 127 0 0 1) 8080)
  server.listen 128
  IO.println "Server is running on port 8080"
  let serverTask := LeanToDo.Http.serve server fun _request => do
    return {
      code := .ok,
      contentType := "text/html",
      body := (← Pages.Project.render app).asString
    }
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
