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
      ],
      batchers: [
        cinema: [],
        musical: [],
        default: []
      ]
    ]

    Broadway.start_link(__MODULE__, options)
  end

  def handle_message(_processor, message, _context) do
    %{data: %{event: event}} = message

    if Tickets.tickets_available?(event) do
      parse_by_batch(message)
    else
      IO.inspect(event, label: "event")
      Broadway.Message.failed(message, "bookings-closed")
    end
  end

  defp parse_by_batch(message) do
    case message do
      %{data: %{event: "cinema"}} = message ->
        Broadway.Message.put_batcher(message, :cinema)
      %{data: %{event: "musical"}} = message ->
        Broadway.Message.put_batcher(message, :musical)
      message ->
        message
    end
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

  def handle_batch(_batcher, messages, batch_info, _context) do
    IO.inspect(batch_info, label: "#{inspect(self())} Batch")
    messages
  end

  def handle_failed(messages, _context) do
    IO.inspect(messages, label: "Failed messages")

    Enum.map(messages, fn
      %{status: {:failed, "bookings-closed"}} = message ->
        Broadway.Message.configure_ack(message, on_failure: :reject)
      message ->
        message
    end)
  end

end
