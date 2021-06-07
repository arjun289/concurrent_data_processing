defmodule BookingsPipeline do
  use Broadway

  @producer BroadwayRabbitMQ.Producer

  @producer_config [
    queue: "bookings_queue",
    declare: [durable: true],
    on_failure: :reject_and_requeue
  ]

  def start_link(_args) do
    options = [
      name: BookingsPipeline,
      producer: [
        module: {@producer, @producer_config}
      ],
      processors: [
        default: [
          concurrency: System.schedulers_online() * 2
        ]
      ]
    ]

    Broadway.start_link(__MODULE__, options)
  end

  def handle_message(_processor, message, _context) do
    %{data: %{event: event, user: user}} = message

    if Tickets.tickets_available?(event) do
      Tickets.create_ticket(user, event)
      Tickets.send_email(user)
    else
      Broadway.Message.failed(message, "booking-closed")
    end

    IO.inspect(message, label: "Message")
  end

  def prepare_messages(messages, _context) do
    messages = Enum.map(messages, fn message ->
      Broadway.Message.update_data(message, fn data ->
        [event, user_id] = String.split(data, ",")
        %{event: event, user_id: user_id}
      end)
    end)

    users = Tickets.user_by_ids(Enum.map(messages, & &1.data.user_id))

    Enum.map(messages, fn message ->
      Broadway.Message.update_data(message, fn data ->
        user = Enum.find(users, & &1.id == data.user_id)
        Map.put(data, :user, user)
      end)
    end)
  end

  def handle_failed(messages, _context) do

  end

end
