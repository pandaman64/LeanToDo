import Verso
import LeanToDo.App
import LeanToDo.Model

open Verso.Output (Html)
open Verso.Output.Html

open LeanToDo.Model

namespace LeanToDo.Pages.Index

set_option autoImplicit false

def renderProject (project : Project) : Html :=
  {{
    <li>
      <a
        href=s!"/project/{project.id}"
        class="block w-full rounded-2xl bg-white px-6 py-5 shadow-sm ring-1 ring-gray-200 transition hover:-translate-y-0.5 hover:shadow-md hover:ring-gray-300 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500"
      >
        <div class="text-lg font-semibold leading-6 text-gray-900">
          {{ project.name }}
        </div>
      </a>
    </li>
  }}

def renderNewProjectForm (edit : Bool) : Html :=
  let midItem : Html :=
    if edit then
      {{
        <div class="flex-1">
          <label for="new-project-name" class="sr-only">"New project"</label>
          <input
            id="new-project-name"
            name="name"
            type="text"
            placeholder="Add a new project"
            autofocus
            class="w-full rounded-lg border border-gray-200 bg-gray-50 px-3 py-2 text-sm text-gray-900 placeholder:text-gray-400 focus:border-indigo-400 focus:bg-white focus:outline-none focus:ring-2 focus:ring-indigo-200"
          />
        </div>
      }}
    else
      {{
        <div class="flex-1">
          <div class="text-sm font-semibold text-gray-900">"Add a new project"</div>
          <div class="text-xs text-gray-400">"Create a fresh space for todos"</div>
        </div>
      }}
  {{
    <li
      class="rounded-2xl border-2 border-dashed border-gray-200 bg-white px-6 py-5 text-gray-500 transition hover:border-indigo-300 hover:text-indigo-600"
      {{
        -- Enable hx-get only when not editing
        if !edit then
          #[("hx-get", "/project/new"), ("hx-swap", "outerHTML")]
        else
          #[]
      }}
    >
      <form
        class="flex w-full items-center gap-3 text-left"
        hx-post="/project/new"
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

def render (app : App) : IO Html := do
  let projects ← listProjects app.db
  return {{
    <html>
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <script src="https://unpkg.com/htmx.org@1.9.12"></script>
        <script src="https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4"></script>
        <title>"LeanToDo"</title>
      </head>
      <body>
        <main class="min-h-screen bg-gray-50">
          <div class="max-w-2xl mx-auto px-4 py-10">
            <header class="mb-6">
              <h1 class="text-3xl font-semibold tracking-tight text-gray-900">"Projects"</h1>
            </header>

            <ul class="flex flex-col gap-3">
              {{ projects.map (renderProject ·) }}
              {{ renderNewProjectForm false }}
            </ul>
          </div>
        </main>
      </body>
    </html>
  }}

end LeanToDo.Pages.Index
