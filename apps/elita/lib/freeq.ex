defmodule Freeq do
  use ExUnit.CaseTemplate

  setup_all do
    script = Path.join([__DIR__, "..", "test", "freeq", "greet.mjs"])
    cmd = System.find_executable("node")

    port = Port.open({:spawn_executable, cmd}, [{:args, [script]}, :binary, :stream])
    :ok = wait_ready(port, 10000)

    on_exit(fn ->
      try do
        Port.command(port, "stop\n")
      rescue
        ArgumentError -> :ok
      end
      wait_video(port, 15000)
      try do
        Port.close(port)
      rescue
        ArgumentError -> :ok
      end
      true
    end)

    {:ok, port: port}
  end

  defp wait_ready(port, timeout) do
    start = System.monotonic_time(:millisecond)
    wait_ready(port, timeout, start)
  end

  defp wait_ready(port, timeout, start) do
    receive do
      {^port, {:data, data}} ->
        if String.contains?(data, "ready") do
          :ok
        else
          elapsed = System.monotonic_time(:millisecond) - start
          if elapsed < timeout do
            wait_ready(port, timeout - elapsed, start)
          else
            {:error, :timeout}
          end
        end

      {^port, {:exit_status, _}} ->
        {:error, :port_closed}
    after
      timeout ->
        {:error, :timeout}
    end
  end

  defp wait_video(port, timeout) do
    start = System.monotonic_time(:millisecond)
    wait_video(port, timeout, start, "")
  end

  defp wait_video(port, timeout, start, buffer) do
    receive do
      {^port, {:data, data}} ->
        combined = buffer <> data
        IO.write(data)
        if String.contains?(combined, "video") or String.contains?(combined, "saw") do
          :ok
        else
          elapsed = System.monotonic_time(:millisecond) - start
          if elapsed < timeout do
            wait_video(port, timeout - elapsed, start, combined)
          else
            :ok
          end
        end

      {^port, {:exit_status, _}} ->
        :ok
    after
      timeout ->
        :ok
    end
  end
end
