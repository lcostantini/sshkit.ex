defmodule SSHKit.Context do
  @moduledoc """
  A context encapsulates the environment for the execution of a task. That is:

  * working directory to start in, see `SSHKit.path/2`
  * user to run as, see `SSHKit.user/2`
  * group, see `SSHKit.group/2`
  * file creation mode mask, see `SSHKit.umask/2`
  * environment variables, see `SSHKit.env/2`

  A context can then be used to run commands, upload or download files:
  See `SSHKit.run/2`, `SSHKit.upload/3` and `SSHKit.download/3`.
  """

  import SSHKit.Utils

  defstruct [env: nil, path: nil, umask: nil, user: nil, group: nil]

  @doc """
  Compiles an executable command string for running the given `command`
  in the provided `context`.

  ## Examples

      iex> %SSHKit.Context{path: "/var/www"} |> SSHKit.Context.build("ls")
      "cd /var/www && /usr/bin/env ls"

      iex> %SSHKit.Context{user: "me"} |> SSHKit.Context.build("whoami")
      "sudo -H -n -u me -- sh -c '/usr/bin/env whoami'"
  """
  def build(context, command) do
    "/usr/bin/env #{command}"
    |> export(context.env)
    |> sudo(context.user, context.group)
    |> umask(context.umask)
    |> cd(context.path)
  end

  defp sudo(command, nil, nil), do: command
  defp sudo(command, username, nil), do: "sudo -H -n -u #{username} -- sh -c #{shellquote(command)}"
  defp sudo(command, nil, groupname), do: "sudo -H -n -g #{groupname} -- sh -c #{shellquote(command)}"
  defp sudo(command, username, groupname), do: "sudo -H -n -u #{username} -g #{groupname} -- sh -c #{shellquote(command)}"

  defp export(command, nil), do: command
  defp export(command, env) when env == %{}, do: command
  defp export(command, env) do
    exports = Enum.map_join(env, " ", fn {name, value} -> "#{name}=\"#{value}\"" end)
    "(export #{exports} && #{command})"
  end

  defp umask(command, nil), do: command
  defp umask(command, mask), do: "umask #{mask} && #{command}"

  defp cd(command, nil), do: command
  defp cd(command, path), do: "cd #{path} && #{command}"
end
