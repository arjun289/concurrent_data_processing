defmodule Tickets do

  @users [
    %{id: "1", email: "foo@email.com"},
    %{id: "2", email: "bar@email.com"},
    %{id: "3", email: "baz@email.com"}
    ]

  def tickets_available?("none") do
    Process.sleep(Enum.random(100..200))
    # true
    false
  end

  def tickets_available?(_event) do
    Process.sleep(Enum.random(100..200))
    true
    # false
  end

  def create_ticket(_user, _event) do
    Process.sleep(Enum.random(250..1000))
  end

  def send_email(_user) do
    Process.sleep(Enum.random(100..250))
  end

  def user_by_ids(ids) when is_list(ids) do
    Enum.filter(@users, & &1.id in ids)
  end
end
