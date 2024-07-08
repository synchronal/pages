ExUnit.start()

Application.put_env(:pages, :phoenix_endpoint, Test.Site.Endpoint)

{:ok, _agent} = Gestalt.start()
{:ok, _} = Test.Site.Endpoint.start_link()
