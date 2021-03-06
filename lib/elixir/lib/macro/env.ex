defmodule Macro.Env do
  @moduledoc """
  A struct that holds compile time environment information.

  The current environment can be accessed at any time as
  `__ENV__`. Inside macros, the caller environment can be
  accessed as `__CALLER__`. It contains the following fields:

    * `module` - the current module name
    * `file` - the current file name as a binary
    * `line` - the current line as an integer
    * `function` - a tuple as `{atom, integer`}, where the first
      element is the function name and the seconds its arity; returns
      `nil` if not inside a function
    * `context` - the context of the environment; it can be `nil`
      (default context), inside a guard or inside an assign
    * `aliases` -  a list of two item tuples, where the first
      item is the aliased name and the second the actual name
    * `requires` - the list of required modules
    * `functions` - a list of functions imported from each module
    * `macros` - a list of macros imported from each module
    * `macro_aliases` - a list of aliases defined inside the current macro
    * `context_modules` - a list of modules defined in the current context
    * `vars` - a list keeping all defined variables as `{var, context}`
    * `export_vars` - a list keeping all variables to be exported in a
      construct (may be `nil`)
    * `lexical_tracker` - PID of the lexical tracker which is responsible to
      keep user info
    * `local` - the module to expand local functions to
  """

  @type name_arity :: {atom, arity}
  @type file :: binary
  @type line :: non_neg_integer
  @type aliases :: [{module, module}]
  @type macro_aliases :: [{module, {integer, module}}]
  @type context :: :match | :guard | nil
  @type requires :: [module]
  @type functions :: [{module, [name_arity]}]
  @type macros :: [{module, [name_arity]}]
  @type context_modules :: [module]
  @type vars :: [{atom, atom | non_neg_integer}]
  @type export_vars :: vars | nil
  @type lexical_tracker :: pid
  @type local :: atom | nil

  @type t :: %{__struct__: __MODULE__,
               module: atom,
               file: file,
               line: line,
               function: name_arity | nil,
               context: context,
               requires: requires,
               aliases: aliases,
               functions: functions,
               macros: macros,
               macro_aliases: aliases,
               context_modules: context_modules,
               vars: vars,
               export_vars: export_vars,
               lexical_tracker: lexical_tracker,
               local: local}

  def __struct__ do
    %{__struct__: __MODULE__,
      module: nil,
      file: "nofile",
      line: 0,
      function: nil,
      context: nil,
      requires: [],
      aliases: [],
      functions: [],
      macros: [],
      macro_aliases: [],
      context_modules: [],
      vars: [],
      export_vars: nil,
      lexical_tracker: nil,
      local: nil}
  end

  @doc """
  Returns a keyword list containing the file and line
  information as keys.
  """
  def location(%{__struct__: Macro.Env, file: file, line: line}) do
    [file: file, line: line]
  end

  @doc """
  Returns whether the compilation environment is currently
  inside a guard.
  """
  def in_guard?(%{__struct__: Macro.Env, context: context}), do: context == :guard

  @doc """
  Returns whether the compilation environment is currently
  inside a match clause.
  """
  def in_match?(%{__struct__: Macro.Env, context: context}), do: context == :match

  @doc """
  Returns the environment stacktrace.
  """
  def stacktrace(%{__struct__: Macro.Env} = env) do
    cond do
      nil?(env.module) ->
        [{:elixir_compiler, :__FILE__, 1, relative_location(env)}]
      nil?(env.function) ->
        [{env.module, :__MODULE__, 0, relative_location(env)}]
      true ->
        {name, arity} = env.function
        [{env.module, name, arity, relative_location(env)}]
    end
  end

  defp relative_location(env) do
    [file: Path.relative_to_cwd(env.file), line: env.line]
  end
end
