defmodule Tracer do
  @moduledoc false
  use GenServer

  def start_link, do: GenServer.start_link(__MODULE__, [], [])
  def start, do: GenServer.start(__MODULE__, [], [])

  def stop(tracer), do: GenServer.stop(tracer)

  def pop_trace(tracer), do: GenServer.call(tracer, :pop_trace)

  # # # Callbacks

  @impl GenServer
  def init(_), do: {:ok, []}

  @impl GenServer
  def terminate(reason, _state) do
    dbg({:terminate, reason})
    :ok
  end

  @impl GenServer
  def handle_info({:trace, _pid, :call, {m, f, a}}, state) do
    {:noreply, [{:call, {m, f, a}} | state]}
  end

  @impl GenServer
  def handle_call(:pop_trace, _from, state) do
    {:reply, Enum.reverse(state), []}
  end
end
