Broker.Supervisor.start_link(3)

Server.Supervisor.start_link()

receive do
  msg -> inspect(msg)
end
