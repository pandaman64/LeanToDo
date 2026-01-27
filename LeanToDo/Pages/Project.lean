import Verso
import LeanToDo.App
import LeanToDo.Model

open Verso.Output (Html)
open Verso.Output.Html

open LeanToDo.Model

namespace LeanToDo.Pages.Project

set_option autoImplicit false

def renderTodo (todo : Todo) : Html :=
  {{
    <li>
      <input type="checkbox" checked=s!"{todo.completed}" />
      <span>{{todo.title}}</span>
    </li>
  }}

def render (app : App) : IO Html := do
  let todos ← listTodos app.db
  return {{
    <html>
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <script src="https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4"></script>
        <title>"LeanToDo"</title>
      </head>
      <body>
        <h1>"Todos"</h1>
        <ul>
          {{ todos.map ({{<li>{{renderTodo ·}}</li>}}) }}
        </ul>
      </body>
    </html>
  }}

end LeanToDo.Pages.Project
