import SQLite
import Verso
import LeanToDo
import Std.Internal.Async

open Std.Internal.IO Async

open Verso.Output (Html)
open Verso.Output.Html

open LeanToDo.Model

def renderTodo (todo : Todo) : Html :=
  {{
    <div>
      <input type="checkbox" checked=s!"{todo.completed}" />
      <span>{{todo.title}}</span>
    </div>
  }}

structure App where
  db : SQLite

def generateHtml (app : App) : IO Html := do
  let todos ← listTodos app.db
  return {{
    <html>
      <body>
        <h1>"Todo List"</h1>
        <ul>
          {{ todos.map ({{<li>{{renderTodo ·}}</li>}}) }}
        </ul>
      </body>
    </html>
  }}

def runServer (app : App) : IO Unit := do
  let server ← TCP.Socket.Server.mk
  server.bind (Std.Net.SocketAddressV4.mk (.ofParts 127 0 0 1) 8080)
  server.listen 128
  IO.println "Server is running on port 8080"
  let serverTask := LeanToDo.Http.serve server fun request => do
    IO.println s!"{request.method} {request.path}, body: {request.body}"
    return {
      code := .ok,
      contentType := "text/html",
      body := (← generateHtml app).asString
    }
  (← serverTask.toIO).block

def prepareDatabase (app : App) : IO Unit := do
  let db := app.db
  db.exec "PRAGMA journal_mode=WAL"
  db.exec "PRAGMA synchronous=NORMAL"
  db.exec "PRAGMA busy_timeout=5000"
  db.exec "DROP TABLE IF EXISTS todos"
  db.exec "CREATE TABLE IF NOT EXISTS todos (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, completed BOOLEAN)"

  let newTodos : Array NewTodo := #[
    { title := "Set up the database", completed := true },
    { title := "Set up the server", completed := true },
    { title := "Incorporate HTMX", completed := false },
    { title := "Incorporate Tailwind CSS", completed := false },
    { title := "Scaffold the HTML components", completed := false },
    { title := "Create a new todo", completed := false },
    { title := "Edit a todo", completed := false },
    { title := "Delete a todo", completed := false },
    { title := "Mark a todo as completed", completed := false },
    { title := "Mark a todo as not completed", completed := false },
    { title := "Delete a todo", completed := false },
  ]
  for todo in newTodos do
    let .some todo ← createTodo todo db | continue
    IO.println s!"Created todo: {todo.id} {todo.title} {todo.completed}"

def main : IO Unit := do
  let app : App := { db := ← SQLite.open "test.db" }
  prepareDatabase app
  runServer app
