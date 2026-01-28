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

def renderNewTodoForm (projectId : Int64) (edit : Bool) : Html :=
  let midItem : Html :=
    if edit then
      {{
        <div class="flex-1">
          <label for="new-todo-title" class="sr-only">"New todo"</label>
          <input
            id="new-todo-title"
            name="title"
            type="text"
            placeholder="Add a new todo"
            class="w-full rounded-lg border border-gray-200 bg-gray-50 px-3 py-2 text-sm text-gray-900 placeholder:text-gray-400 focus:border-indigo-400 focus:bg-white focus:outline-none focus:ring-2 focus:ring-indigo-200"
          />
        </div>
      }}
    else
      {{
        <div class="flex-1">
          <div class="text-sm font-semibold text-gray-900">"Add a new todo"</div>
          <div class="text-xs text-gray-400">"Capture a task for this project"</div>
        </div>
      }}
  {{
    <li
      class="rounded-xl border-2 border-dashed border-gray-200 bg-white px-3 py-3 text-gray-500 transition hover:border-indigo-300 hover:text-indigo-600"
      {{
        -- Enable hx-get only when not editing
        if !edit then
          #[("hx-get", s!"/project/{projectId}/new"), ("hx-swap", "outerHTML")]
        else
          #[]
      }}
    >
      <form
        class="flex w-full items-center gap-3 text-left"
        hx-post=s!"/project/{projectId}/new"
        hx-target="body"
        hx-swap="outerHTML"
      >
        <span class="inline-flex size-9 items-center justify-center rounded-full bg-indigo-50 text-indigo-600 ring-1 ring-indigo-100">
          "+"
        </span>
        {{ midItem }}
        {{
          if edit then
            {{
              <input type="hidden" name="projectId" value=s!"{projectId}" />
              <button
                type="submit"
                class="inline-flex items-center gap-2 rounded-lg bg-indigo-600 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-indigo-700 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-400 focus-visible:ring-offset-2"
              >
                "Add"
              </button>
            }}
          else
            .empty
        }}
      </form>
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
              {{ renderNewTodoForm projectId false }}
            </ul>
          </div>
        </main>
      </body>
    </html>
  }}

end LeanToDo.Pages.Project
