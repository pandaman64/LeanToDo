import SQLite
import Verso

open Verso.Output (Html)
open Verso.Output.Html

structure Todo where
  id : Int64
  title : String
  completed : Bool
deriving Repr

instance : SQLite.Row Todo where
  read := do
    return {
      id := ← SQLite.Row.read,
      title := ← SQLite.Row.read,
      completed := (← SQLite.Row.read) != (0 : Int64)
    }

def renderTodo (todo : Todo) : Html :=
  {{
    <div>
      <input type="checkbox" checked=s!"{todo.completed}" />
      <span>{{todo.title}}</span>
    </div>
  }}

def main : IO Unit := do
  let db ← SQLite.open "test.db"
  db.exec "CREATE TABLE IF NOT EXISTS todos (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, completed BOOLEAN)"
  db.exec "INSERT INTO todos (title, completed) VALUES ('Buy groceries', FALSE)"
  db.exec "INSERT INTO todos (title, completed) VALUES ('Buy a new phone', FALSE)"
  db.exec "INSERT INTO todos (title, completed) VALUES ('Buy a new car', FALSE)"
  db.exec "INSERT INTO todos (title, completed) VALUES ('Buy a new house', FALSE)"
  db.exec "INSERT INTO todos (title, completed) VALUES ('Buy a new boat', FALSE)"
  db.exec "INSERT INTO todos (title, completed) VALUES ('Buy a new plane', FALSE)"
  db.exec "INSERT INTO todos (title, completed) VALUES ('Buy a new train', FALSE)"
  db.exec "INSERT INTO todos (title, completed) VALUES ('Buy a new ship', FALSE)"
  db.exec "INSERT INTO todos (title, completed) VALUES ('Buy a new bike', FALSE)"

  IO.println "----- After insert -----"
  let selectStmt ← db.prepare "SELECT * FROM todos"
  for todo in selectStmt.resultsAs Todo do
    IO.println s!"{todo.id} {todo.title} {todo.completed}"

  db.exec "UPDATE todos SET completed = TRUE WHERE id = 4"

  IO.println "----- After update -----"
  let selectStmt ← db.prepare "SELECT * FROM todos"
  for todo in selectStmt.resultsAs Todo do
    IO.println s!"{todo.id} {todo.title} {todo.completed}"

  let todos ← (selectStmt.resultsAs Todo).toArray
  let html := {{
    <html>
      <body>
        <h1>"Todo List"</h1>
        <ul>
          {{ todos.map ({{<li>{{renderTodo ·}}</li>}}) }}
        </ul>
      </body>
    </html>
  }}
  IO.println html.asString

  db.exec "DROP TABLE todos"
