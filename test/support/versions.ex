defmodule Test.Versions do
  def otp do
    major = :erlang.system_info(:otp_release) |> List.to_string()
    vsn_file = Path.join([:code.root_dir(), "releases", major, "OTP_VERSION"])

    {:ok, contents} = File.read(vsn_file)

    String.split(contents, "\n", trim: true)
    |> List.first()
  end
end
