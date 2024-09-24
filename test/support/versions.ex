defmodule Test.Versions do
  def otp do
    full_otp_version()
    |> String.split(".")
    |> Enum.take(3)
    |> then(fn
      [a, b] -> [a, b, "0"]
      versions -> versions
    end)
    |> Enum.join(".")
  end

  defp full_otp_version do
    major = :erlang.system_info(:otp_release) |> List.to_string()
    vsn_file = Path.join([:code.root_dir(), "releases", major, "OTP_VERSION"])

    {:ok, contents} = File.read(vsn_file)

    String.split(contents, "\n", trim: true)
    |> List.first()
  end
end
