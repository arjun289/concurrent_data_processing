defmodule Sender do
  @moduledoc """
  Documentation for Sender.
  """

  def send_email(email) do
    Process.sleep(30_000)
    IO.puts("Email to #{email} sent")
    {:ok, "email_sent"}
  end

  def notify_all(emails) do
    Enum.map(emails, fn email ->
      Task.async(fn ->
        send_email(email)
      end)
    end)
  end
end
