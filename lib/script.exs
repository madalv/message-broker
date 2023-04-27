Server.Supervisor.start_link()

Topic.Supervisor.start_link()

receive do
  msg -> inspect(msg)
end
