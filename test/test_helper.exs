ExUnit.start()

defmodule TestHelpers do
  def tap(collection, tap_func) do
    tap_func.(collection)
    collection
  end
end
