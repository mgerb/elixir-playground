defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller
  alias MyAppWeb.Response
  alias MyApp.Data

  def index(conn, params) do
    IO.puts (Map.values(params))
    conn
    |> Response.json("Auth works!")
  end

  def login(conn, %{"email" => email, "password" => password}) when not is_nil(email) and not is_nil(password) do
    {output, status} = case Data.User.get_user(email, password) do
      {:error, error} -> {error, 400}
      {:ok, data} -> {data, 200}
    end

    conn
    |> put_status(status)
    |> Response.json(output)
  end
  
  def login(conn, _) do
    conn
    |> put_status(400)
    |> Response.json("Invalid login")
  end
  
  def create_user(conn, params) do
    
    changeset = Data.User.changeset(%Data.User{}, hash_password(params))

    # store user in database and return errors
    {output, status} = case Data.User.store_user(changeset) do
      {:ok, _} -> {"success", 200}
      {:error, changeset} ->
        errors = Enum.map(changeset.errors, fn {key, val} ->
          %{key => elem(val, 0)}
        end)
        {errors, 400}
    end

    conn
    |> put_status(status)
    |> Response.json(output)
  end
  
  # check if password exists and hash it
  defp hash_password(params) do
    case Map.get(params, "password") do
      nil -> params
      password -> Map.put(params, "password", Comeonin.Argon2.hashpwsalt(password))
    end
  end

  def upload(conn, %{"file" => file}) when not is_nil(file) do
    if not File.exists?("./uploads"), do: File.mkdir!("./uploads")
    File.cp!(file.path, "./uploads/#{file.filename}")
    Response.json(conn, "File uploaded")
  end
  
  def upload(conn, _) do
    conn
    |> put_status(400)
    |> Response.json("Invalid file")
  end

end
