defmodule MiniRepo.Endpoint do
  @moduledoc false

  use Plug.Builder
  require Logger

  plug Plug.Logger

  plug Plug.Static,
    at: "/repos",
    from: {:mini_repo, "data/repos"}

  plug :non_existing_package

  plug MiniRepo.APIAuth
  plug MiniRepo.APIRouter, builder_opts()

  def non_existing_package(
        %Plug.Conn{method: meth, path_info: ["repos", repo, "packages", package]} = conn,
        _
      )
      when meth in ["GET", "HEAD"] do
    Logger.info("Package not found for #{repo}: #{package}")
    repositories = Application.get_env(:mini_repo, :repositories, [])

    name =
      Enum.find_value(repositories, fn {k, _r} ->
        if "#{k}" == repo, do: k
      end)

    MiniRepo.Mirror.Server.add_package(name, package)

    conn
    |> put_resp_header("location", conn.request_path)
    |> send_resp(302, "")
    |> halt()
  end

  def non_existing_package(conn, _) do
    conn
  end
end
