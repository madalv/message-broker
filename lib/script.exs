ServerSupervisor.start_link()

receive do
  msg -> inspect(msg)
end
