import SQLite

namespace LeanToDo.Model

structure Todo where
  id : Int64
  projectId : Int64
  title : String
  completed : Bool
deriving Repr

instance : SQLite.Row Todo where
  read := do
    return {
      id := ← SQLite.Row.read,
      projectId := ← SQLite.Row.read,
      title := ← SQLite.Row.read,
      completed := (← SQLite.Row.read) != (0 : Int64)
    }

instance : Lean.ToJson Todo where
  toJson todo := .mkObj [
    ("id", .num todo.id.toInt),
    ("projectId", .num todo.projectId.toInt),
    ("title", .str todo.title),
    ("completed", .bool todo.completed),
  ]

structure NewTodo where
  projectId : Int64
  title : String
  completed : Bool := false
deriving Repr

def createTodo (todo : NewTodo) (db : SQLite) := do
  let results ← db query!"
    INSERT INTO todos (project_id, title, completed)
    VALUES ({todo.projectId}, {todo.title}, {todo.completed})
    RETURNING id, project_id, title, completed
  " as Todo
  return (← results.toArray)[0]?

def listTodos (db : SQLite) : IO (Array Todo) := do
  let results ← db query!"SELECT id, project_id, title, completed FROM todos" as Todo
  results.toArray

def listTodosByProject (projectId : Int64) (db : SQLite) : IO (Array Todo) := do
  let results ← db query!"
    SELECT id, project_id, title, completed
    FROM todos
    WHERE project_id = {projectId}
  " as Todo
  results.toArray

def getTodo (id : Int64) (db : SQLite) : IO (Option Todo) := do
  let results ← db query!"SELECT id, project_id, title, completed FROM todos WHERE id = {id}" as Todo
  -- Why don't we have `results.atIdx? 0`?
  return (← results.toArray)[0]?

def updateTodo (todo : Todo) (db : SQLite) := do
  let stmt ← db sql!"
    UPDATE todos
    SET project_id = {todo.projectId}, title = {todo.title}, completed = {todo.completed}
    WHERE id = {todo.id}
  "
  stmt.exec

def deleteTodo (id : Int64) (db : SQLite) := do
  let stmt ← db sql!"DELETE FROM todos WHERE id = {id}"
  stmt.exec

end LeanToDo.Model
