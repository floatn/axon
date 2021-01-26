defmodule Axon.Initializers do
  @moduledoc """
  Common parameter initializers.
  """

  # TODO: These should all be defn
  # TODO: Add random keys
  # TODO: orthogonal - requires `qr`

  @doc """
  Initializes parameters to 0.

  ## Examples

      iex> Nx.zeros({2, 2})
      #Nx.Tensor<
        f32[2][2]
        [
          [0.0, 0.0],
          [0.0, 0.0]
        ]
      >
  """
  def zeros(shape, opts \\ []) do
    type = opts[:type] || {:f, 32}
    Nx.broadcast(Nx.tensor(0, type: type), shape)
  end

  @doc """
  Initializes parameters to 1.

  ## Examples

      iex> Nx.ones({2, 2})
      #Nx.Tensor<
        f32[2][2]
        [
          [1.0, 1.0],
          [1.0, 1.0]
        ]
      >
  """
  def ones(shape, opts \\ []) do
    type = opts[:type] || {:f, 32}
    Nx.broadcast(Nx.tensor(1, type: type), shape)
  end

  @doc """
  Initializes parameters with a random uniform distribution.
  """
  def uniform(shape, opts \\ []) do
    type = opts[:type] || {:f, 32}
    scale = opts[:scale] || 1.0e-2
    Nx.random_uniform(shape, type: type) * scale
  end

  @doc """
  Initializes parameters with a random normal distribution.
  """
  def normal(shape, opts \\ []) do
    type = opts[:type] || {:f, 32}
    scale = opts[:scale] || 1.0e-2
    mean = opts[:mean] || 0.0
    Nx.random_normal(shape, mean, scale, type: type)
  end

  @doc """
  Lecun uniform initializer.
  """
  def lecun_uniform(shape, opts \\ []) do
    type = opts[:type] || {:f, 32}
    scale = opts[:scale] || 1.0
    variance_scaling(shape, type: type, scale: scale, mode: :fan_in, distribution: :uniform)
  end

  @doc """
  Lecun normal initializer.
  """
  def lecun_normal(shape, opts \\ []) do
    type = opts[:type] || {:f, 32}
    scale = opts[:scale] || 1.0
    variance_scaling(shape, type: type, scale: scale, mode: :fan_in, distribution: :truncated_normal)
  end

  @doc """
  Glorot uniform initializer.
  """
  def glorot_uniform(shape, opts \\ []) do
    type = opts[:type] || {:f, 32}
    scale = opts[:scale] || 1.0
    variance_scaling(shape, type: type, scale: scale, mode: :fan_avg, distribution: :uniform)
  end

  @doc """
  Glorot normal initializer.
  """
  def glorot_normal(shape, opts \\ []) do
    type = opts[:type] || {:f, 32}
    scale = opts[:scale] || 1.0
    variance_scaling(shape, type: type, scale: scale, mode: :fan_avg, distribution: :truncated_normal)
  end

  @doc """
  He Uniform initializer.
  """
  def he_uniform(shape, opts \\ []) do
    type = opts[:type] || {:f, 32}
    scale = opts[:scale] || 2.0
    variance_scaling(shape, type: type, scale: scale, mode: :fan_in, distribution: :uniform)
  end

  @doc """
  He Uniform initializer.
  """
  def he_normal(shape, opts \\ []) do
    type = opts[:type] || {:f, 32}
    scale = opts[:scale] || 2.0
    variance_scaling(shape, type: type, scale: scale, mode: :fan_in, distribution: :truncated_normal)
  end

  @doc """
  Initializes parameters using variance scaling with the given
  distribution and mode.
  """
  def variance_scaling(shape, opts \\ []) do
    type = opts[:type] || {:f, 32}
    scale = opts[:scale] || 1.0e-2
    mode = opts[:mode] || :fan_in
    distribution = opts[:distribution] || :normal

    {fan_in, fan_out} = compute_fans(shape)

    denominator =
      case mode do
        :fan_in -> fan_in
        :fan_out -> fan_out
        :fan_avg -> (fan_in + fan_out) / 2.0
      end

    variance = Nx.divide(Nx.tensor(scale, type: type), Nx.tensor(denominator, type: type))

    case distribution do
      :normal ->
        Nx.random_normal(shape, type: type) * Nx.sqrt(variance)
      :uniform ->
        Nx.random_uniform(shape, type: type) * Nx.sqrt(Nx.multiply(3.0, variance))
      :truncated_normal ->
        stddev = Nx.divide(Nx.sqrt(variance), Nx.tensor(0.87962566103423978, type: type))
        Nx.multiply(Nx.clip(Nx.random_normal(shape, type: type), -2.0, 2.0), stddev)
    end
  end

  # Helpers

  defp compute_fans(shape) do
    receptive_field_size = tuple_product(shape, tuple_size(shape)) / elem(shape, 0) / elem(shape, 1)
    fan_in = elem(shape, 0) * receptive_field_size
    fan_out = elem(shape, 1) * receptive_field_size
    {fan_in, fan_out}
  end

  # TODO: Replace with Tuple.product on Elixir v1.12
  defp tuple_product(_tuple, 0), do: 1
  defp tuple_product(tuple, i), do: :erlang.element(i, tuple) * tuple_product(tuple, i - 1)

end