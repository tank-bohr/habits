defmodule Habits.Auth do
  @moduledoc """
  Responsible for authentication of accounts such as when logging in or out.
  """

  import Ecto, only: [assoc: 2]
  # import Ecto.Changeset
  import Ecto.Query
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]

  alias Habits.Repo
  alias Habits.Accounts
  alias Habits.Accounts.Account
  alias Habits.Auth.Session

  def get_account_id_from_token(token) do
    case Repo.get_by(Session, token: token) do
      nil -> {:error, "Invalid token"}
      session -> {:ok, session.account_id}
    end
  end

  def log_in(email, password, location \\ nil) do
    account = Accounts.get_by_email(email)
    cond do
      account && checkpw(password, account.encrypted_password) ->
        session_changeset =
          Session.changeset(%Session{}, %{
            account_id: account.id,
            location: format_location(location)
          })

        Repo.insert(session_changeset)

      true ->
        dummy_checkpw()
        {:error, :unauthorized}
    end
  end

  def log_out(token) do
    case Repo.get_by(Session, token: token) do
      nil ->
        {:error, :invalid_token}
      session ->
        Repo.delete(session)
        :ok
    end
  end

  def list_sessions(%Account{} = account) do
    account
    |> assoc(:sessions)
    |> order_by(desc: :id)
    |> Repo.all()
  end

  defp format_location(%GeoIP.Location{city: city, region_name: region, country_name: country})
    when city not in ["", nil] and region not in ["", nil] and country not in ["", nil] do
      city <> ", " <> region <> ", " <> country
  end
  defp format_location(_), do: Session.default_location()
end
