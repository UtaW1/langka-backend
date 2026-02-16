defmodule LangkaOrderManagement.Jwt do
  @moduledoc """
  jwt utility module
  """

  def signs(claims) do
    jwk = JOSE.JWK.from_pem(private_key())
    jwt = %{"alg" => jwt_alg()}
    {_, token} =
      jwk
      |> JOSE.JWT.sign(jwt, claims)
      |> JOSE.JWS.compact()

    token
  end

  def verify(token) do
    jwk = JOSE.JWK.from_pem(public_key())

    case JOSE.JWT.verify_strict(jwk, [jwt_alg()], token) do
      {true, jwt, _jws} ->
        {:ok, jwt.fields}

      _ ->
        {:error, :invalid}
    end
  end

  defp jwt_alg, do: fetch!(:jwt_alg)
  defp private_key, do: fetch!(:private_key) |> String.replace("\\n", "\n")
  defp public_key, do: fetch!(:public_key) |> String.replace("\\n", "\n")

  defp fetch!(key) do
    Application.fetch_env!(:langka_order_management, LangkaOrderManagement.Auth)[key]
  end
end
