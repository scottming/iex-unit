defmodule IExUnit.Compiler do
  def compile(files, options) do
    case Kernel.ParallelCompiler.compile(files) do
      {:ok, _, _} ->
        :ok

      error ->
        write_compile_error_on_configured(error, options)
        error
    end
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

