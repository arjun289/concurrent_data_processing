
defmodule SendServer do
  use GenServer


  def init(args) do
    IO.inspect("Received arguments: #{inspect(args)}")
    max_retries = Keyword.get(args, :max_retries, 5)

    state = %{emails: [], max_retries: max_retries}

    Process.send_after(self(), :retry, 5000)
    {:ok, state}
  end

  def handle_continue(:fetch_from_database, state) do
    users = []
    {:noreply, Map.put(state, :user, users)}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:send, email}, state) do
    status =
    case Sender.send_email(email) do
      {:ok, "email_sent"} -> "sent"
      :error -> "failed"
    end
    emails = [%{email: email, status: status, retries: 0}] ++ state.emails
    {:noreply, Map.put(state, :emails, emails)}
  end

  def send_email("konnichiwa@world.com" = _email),
    do: :error
  def send_email(email) do
    Process.sleep(3000)
    IO.puts("Email to #{email} sent")
    {:ok, "email sent"}
  end

  def handle_info(:retry, state) do
    {failed, done} = Enum.split_with(state.emails,
       fn item ->
        item.status == "failed" && item.retries < state.max_retries
      end
    )

    retried = Enum.map(failed, fn item ->
      IO.puts("Retyring email #{item.email}...")
      new_status = case Sender.send_email(item.email) do
          {:ok, "email_sent"} -> "sent"
          :error -> "failed"
        end
      %{email: item.email, status: new_status, retries: item.retries + 1}
    end)
    Process.send_after(self(), :retry, 5000)

    {:noreply, Map.put(state, :emails, retried ++ done)}
  end

  def terminate(reason, _state) do
    IO.puts("Terminating with reason #{reason}")
  end

end
