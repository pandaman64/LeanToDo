import SQLite

namespace LeanToDo.Model

structure Project where
  id : Int64
  name : String
deriving Repr

instance : SQLite.Row Project where
  read := do
    return {
      id := ← SQLite.Row.read,
      name := ← SQLite.Row.read
    }

structure NewProject where
  name : String
deriving Repr

def createProject (project : NewProject) (db : SQLite) := do
  let results ← db query!"
    INSERT INTO projects (name) VALUES ({project.name})
    RETURNING id, name
  " as Project
  return (← results.toArray)[0]?

def listProjects (db : SQLite) : IO (Array Project) := do
  let results ← db query!"SELECT id, name FROM projects" as Project
  results.toArray

def getProject (id : Int64) (db : SQLite) : IO (Option Project) := do
  let results ← db query!"SELECT id, name FROM projects WHERE id = {id}" as Project
  return (← results.toArray)[0]?

def updateProject (project : Project) (db : SQLite) := do
  let stmt ← db sql!"UPDATE projects SET name = {project.name} WHERE id = {project.id}"
  stmt.exec

def deleteProject (id : Int64) (db : SQLite) := do
  let stmt ← db sql!"DELETE FROM projects WHERE id = {id}"
  stmt.exec

end LeanToDo.Model
