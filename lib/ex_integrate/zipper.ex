defmodule ExIntegrate.Core.Zipper do
  @moduledoc """
  A set of functions operating on zippers. For now, zippers are in two
  dimensions only.

  The internal structure of a zipper should be considered opaque and subject to
  change. To get or update the current item, traverse the zipper, or perform any
  other operation on the zipper, use the public functions exposed in this
  module.

  References:
    * [Wikipedia](https://en.wikipedia.org/wiki/Zipper_(data_structure))
    * [Gerard Huet's original paper](https://www.st.cs.uni-saarland.de/edu/seminare/2005/advanced-fp/docs/huet-zipper.pdf)
    * [Clojure stdlib](https://clojuredocs.org/clojure.zip/zipper)
    * [ElixirForum post](https://elixirforum.com/t/elixir-needs-a-fifo-type/5701/24)
  """

  @opaque t :: {left :: term, current :: term, right :: term}
  @opaque t(l, current, r) :: {l, current, r}

  defmodule TraversalError do
    defexception [:message]

    @impl Exception
    def exception(value) do
      msg = "cannot traverse the zipper in this direction. #{inspect(value)}"
      %TraversalError{message: msg}
    end
  end

  @spec zip(val) :: t([], nil, val) when val: list
  def zip(list) when is_list(list) do
    {[], nil, list}
  end

  @spec node(t) :: term
  def node({_l, current, _r}),
    do: current

  @spec right(t) :: t
  def right({_, _, []} = zipper),
    do: raise(TraversalError, zipper)

  def right({l, old_current, [head_r | tail_r]}),
    do: {[old_current | l], head_r, tail_r}

  @spec put_current(t, term) :: t
  def put_current({l, _current_value, r}, new_value),
    do: {l, new_value, r}
end
