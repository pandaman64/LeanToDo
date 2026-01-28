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
    <li id=s!"todo-{todo.id}" class="rounded-xl bg-white px-3 py-3 shadow-sm ring-1 ring-gray-200 transition hover:shadow-md hover:ring-gray-300">
      <div class="flex items-center gap-2">
        <button
          type="button"
          class={{
            if todo.completed then
              "inline-flex size-9 items-center justify-center rounded-full bg-emerald-100 text-emerald-700 ring-1 ring-emerald-200 hover:bg-emerald-200"
            else
              "inline-flex size-9 items-center justify-center rounded-full bg-white text-gray-500 ring-1 ring-gray-200 hover:bg-gray-100"
          }}
          aria-label=s!"Toggle completed for todo {todo.id}"
          hx-post=s!"/todos/{todo.id}"
          hx-vals={{ { todo with completed := !todo.completed } |> Lean.toJson |> toString }}
          hx-target="closest li"
          hx-swap="outerHTML"
        >
          <span class="text-sm font-semibold">
            {{ if todo.completed then "✓" else "○" }}
          </span>
        </button>

        <div class={{
          if todo.completed then
            "flex-1 px-3 text-gray-400 line-through"
          else
            "flex-1 px-3 text-gray-900"
        }}>
          <div class="font-medium leading-5">
            {{ todo.title }}
          </div>
        </div>

        <button
          type="button"
          class="inline-flex size-9 items-center justify-center rounded-full bg-white text-rose-600 ring-1 ring-rose-200 hover:bg-rose-50"
          aria-label=s!"Delete todo {todo.id}"
          hx-delete=s!"/todos/{todo.id}"
          hx-target="closest li"
          hx-swap="outerHTML swap:100ms"
        >
          <span class="text-sm font-semibold">"×"</span>
        </button>
      </div>
    </li>
  }}

def render (projectId : Int64) (app : App) : IO Html := do
  let .some project ← LeanToDo.Model.getProject projectId app.db | throw <| IO.userError "Project not found"
  let todos ← LeanToDo.Model.listTodosByProject projectId app.db
  return {{
    <html>
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <script src="https://unpkg.com/htmx.org@1.9.12"></script>
        <script src="https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4"></script>
        <title>s!"LeanToDo - {project.name}"</title>
      </head>
      <body>
        <main class="min-h-screen bg-gray-50">
          <div class="max-w-2xl mx-auto px-4 py-10">
            <header class="mb-6 space-y-3">
              <a
                href="/"
                class="inline-flex items-center text-sm font-medium text-gray-500 hover:text-gray-700 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500"
              >
                "← Back to projects"
              </a>
              <h1 class="text-3xl font-semibold tracking-tight text-gray-900">s!"Todos: {project.name}"</h1>
            </header>

            <ul class="flex flex-col gap-3">
              {{ todos.map (renderTodo ·) }}
            </ul>
          </div>
        </main>
      </body>
    </html>
  }}

end LeanToDo.Pages.Project
