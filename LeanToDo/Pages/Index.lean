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
    <li class="rounded-2xl bg-white px-6 py-5 shadow-sm ring-1 ring-gray-200">
      <div class="text-lg font-semibold leading-6 text-gray-900">
        {{ project.name }}
      </div>
    </li>
  }}

def render (app : App) : IO Html := do
  let projects ← listProjects app.db
  return {{
    <html>
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
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
            </ul>
          </div>
        </main>
      </body>
    </html>
  }}

end LeanToDo.Pages.Index
