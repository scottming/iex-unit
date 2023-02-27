defmodule IExUnit do
  @moduledoc """
  A utility module that helps you iterate faster on unit tests.
  This module lets execute specific tests from within a running iex shell to
  avoid needing to start and stop the whole application every time.
  """

  @doc """
  Starts the testing context.
  ## Examples
      iex> IExUnit.start()
  """
  def start() do
    ExUnit.start()
    Code.compiler_options(ignore_module_conflict: true)

    if File.exists?("test/test_helper.exs") do
      Code.eval_file("test/test_helper.exs", File.cwd!())
    end

    :ok
  end

  @doc """
  Loads or reloads testing helpers
  ## Examples
      iex> IExUnit.load_helper(“test/test_helper.exs”)
  """
  def load_helper(file_name) do
    Code.eval_file(file_name, File.cwd!())
  end

  @doc """
  Runs a single test, a test file, or multiple test files
  ## Example: Run a single test
      iex> IExUnit.run("./path/test/file/test_file_test.exs", line: line_number)
  ## Example: Run a single test file
      iex> IExUnit.run("./path/test/file/test_file_test.exs")
  ## Example: Run a single test file with a specific seed
      iex> IExUnit.run("./path/test/file/test_file_test.exs", seed: seed_number)
  ## Example: Run several test files:
      iex> IExUnit.run(["./path/test/file/test_file_test.exs", "./path/test/file/test_file_2_test.exs"])
  """
  def run(path, options \\ [])

  def run(path, options) do
    options = opts_for_line(options) ++ opts_for_seed(options)
    ExUnit.configure(options)
    IEx.Helpers.recompile()
    Code.compile_file(path)
    server_modules_loaded()
    ExUnit.run()
  end

  defp opts_for_line(options) do
    line = Keyword.get(options, :line)

    if line do
      [exclude: [:test], include: [line: line]]
    else
      [exclude: [], include: []]
    end
  end

  defp opts_for_seed(options) do
    seed = Keyword.get(options, :seed)
    if seed, do: [seed: seed], else: []
  end

  if System.version() > "1.14.1" do
    defp server_modules_loaded(), do: ExUnit.Server.modules_loaded(false)
  else
    defp server_modules_loaded(), do: ExUnit.Server.modules_loaded()
  end
end
