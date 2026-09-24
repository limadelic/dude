defmodule ElitaRoot.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      aliases: aliases()
    ]
  end

  defp aliases do
    [
      freeq: [fn _ -> run_freeq() end]
    ]
  end

  defp run_freeq do
    File.cd!("apps/elita")
    Mix.Task.run("test", ["--only", "freeq", "--warnings-as-errors"])
  end
end
