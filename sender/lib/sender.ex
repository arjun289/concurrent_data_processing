defmodule Sender do
  @moduledoc """
  Documentation for Sender.
  """

  def send_email(email) do
    Process.sleep(1000)
    IO.puts("Email to #{email} sent")
    {:ok, "email_sent"}
  end

  @spec notify_all(any) :: list
  def notify_all(emails) do
    Enum.map(emails, fn email ->
      Task.async(fn ->
        send_email(email)
      end)
    end)
  end
end
