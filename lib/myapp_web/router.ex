defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end
  
  pipeline :api_auth do
    plug MyApp.Guardian.AuthPipeline.JSON
  end

  # Other scopes may use custom stacks.
  scope "/api", MyAppWeb do
    pipe_through [:api]

    scope "/user" do

      # unauthenticated routes
      post "/login", UserController, :login
      post "/create", UserController, :create_user


      # authenticated routes
      pipe_through [:api_auth]
      get "/", UserController, :index
      post "/upload", UserController, :upload

    end
  end
  
end
