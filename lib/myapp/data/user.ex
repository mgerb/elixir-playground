defmodule MyApp.Data.User do
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset
  alias MyApp.Repo

  schema "user" do
    field :first_name, :string
    field :last_name, :string
    field :email, :string
    field :password, :string

    timestamps()
  end

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, [:first_name, :last_name, :email, :password])
    |> validate_required([:first_name, :last_name, :email, :password])
    |> unique_constraint(:email)
  end

  def store_user(user) do
    Repo.insert(user)
  end

  def get_user(email, password) do
    query = from u in "user",
      where: u.email == ^email,
      select: [:id, :email, :password, :first_name, :last_name]

    Repo.one(query)
    |> validate_password(password)
    |> generate_auth_token()
  end
  
  defp validate_password(nil, _), do: {:error, "No user found"} 
  
  defp validate_password(data, password) when not is_nil(data) do
    case Comeonin.Argon2.checkpw(password, data.password) do
      true -> {:ok, Map.delete(data, :password)} # remove password from return data
      false -> {:error, "Invalid password"}
    end
  end
  
  defp generate_auth_token({:error, data}), do: {:error, data}
  
  defp generate_auth_token({:ok, user}) do
    case MyApp.Guardian.encode_and_sign(user, map_claims(user), ttl: tokenTTL()) do
      {:ok, token, _claims} -> {:ok, Map.merge(user, %{ token: token })}
      {:error, _token, _claims} -> {:error, "JWT error"}
    end
  end
  
  # ~1 year
  defp tokenTTL(), do: {52, :weeks}

  defp map_claims(user) do
    %{
      id: user.id,
      first_name: user.first_name,
      last_name: user.last_name,
      email: user.email,
    }
  end

end
