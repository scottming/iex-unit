defmodule IExUnit do
  @moduledoc """
  Copied some code from here: https://github.com/Olshansk/test_iex/blob/9bafb3bc4e89555ab7ad87b9593b1bfc6b71caaa/lib/test_iex.ex, 
  but added more features to support VScode and Neovim.

  Copyright (c) 2019 - 2021 Daniel Olshansky
  Copyright (c) 2023 Scott Ming

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
  ## Example: Run all tests in a directory:
      iex> IExUnit.run("test")
  """
  def run(path, options \\ [])

  def run(path, options) do
    paths =
      path
      |> List.wrap()
      |> Enum.map(fn p -> if File.dir?(p), do: ls(p), else: p end)
      |> List.flatten()
      |> Enum.map(&Path.relative_to_cwd/1)

    run_test(paths, options)
  end

  defp ls(dir) do
    abs_dir = Path.expand(".", dir)
    Path.wildcard("#{abs_dir}/**/*_test.exs")
  end

  defp run_test(files, options) do
    IEx.Helpers.recompile()

    case Kernel.ParallelCompiler.compile(files) do
      {:ok, _, _} ->
        configure(options)
        server_modules_loaded()
        ExUnit.run()

      error ->
        write_compile_error_on_configured(error, options)
        error
    end
  end

  defp configure(options) do
    options = opts_for_line(options) ++ opts_for_seed(options) ++ opts_for_output_dir(options)
    ExUnit.configure(options)
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

  defp opts_for_output_dir(options) do
    output_dir = Keyword.get(options, :output_dir)
    if output_dir, do: [output_dir: output_dir], else: []
  end

  if System.version() > "1.14.1" do
    defp server_modules_loaded(), do: ExUnit.Server.modules_loaded(false)
  else
    defp server_modules_loaded(), do: ExUnit.Server.modules_loaded()
  end

  defp write_compile_error_on_configured(error, options) do
    {:error, messages, suggestions} = error
    output_dir = options[:output_dir]

    if output_dir do
      error_message = extract_error_string(messages, suggestions)
      write_compile_error(output_dir, options[:seed], error_message)
    else
      :ok
    end
  end

  defp write_compile_error(output_dir, seed, message) do
    File.mkdir_p!(output_dir)
    compile_error_path = Path.join(output_dir, "compile_error")
    {:ok, compile_error_file} = File.open(compile_error_path, [:write])
    IO.write(compile_error_file, "#{seed}:#{message}")
    File.close(compile_error_file)
  end

  defp extract_error_string(error, suggestions) when is_list(error) and suggestions != [] do
    messages = for {_test, _line, message} <- error, do: message
    suggestions = for {_test, _line, suggestion} <- suggestions, do: suggestion

    [messages, suggestions]
    |> Enum.zip_reduce([], fn pairs, acc -> [Enum.join(pairs, "") | acc] end)
    |> Enum.join("---")
  end

  defp extract_error_string(error, _) when is_list(error) do
    for({_test, _line, message} <- error, do: message)
    |> Enum.join("---")
  end
end
