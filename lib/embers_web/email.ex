defmodule EmbersWeb.Email do
  @moduledoc """
  A module for sending emails to the user.
  This module provides functions to be used with the Phauxth authentication
  library when confirming users or handling password resets. It uses
  Bamboo, with the Mandrill adapter, to email users. For tests, it uses
  a test adapter, which is configured in the config/test.exs file.
  If you want to use a different email adapter, or another email
  library, read the instructions below.
  ## Bamboo with a different adapter
  Bamboo has adapters for Mailgun, Mailjet, Mandrill, Sendgrid, SMTP,
  SparkPost, PostageApp, Postmark and Sendcloud.
  There is also a LocalAdapter, which is great for local development.
  See [Bamboo](https://github.com/thoughtbot/bamboo) for more information.
  ## Other email library
  If you do not want to use Bamboo, follow the instructions below:
  1. Edit this file, using the email library of your choice
  2. Remove the lib/forks_the_egg_sample/mailer.ex file
  3. Remove the Bamboo entries in the config/config.exs and config/test.exs files
  4. Remove bamboo from the deps section in the mix.exs file
  """

  import Swoosh.Email

  alias EmbersWeb.Mailer

  @doc """
  An email with a confirmation link in it.
  """
  def confirm_request(address, key) do
    host = host()

    prep_mail(address)
    |> subject("Confirmar cuenta")
    |> text_body("Confirma tu cuenta en este enlace http://#{host}/confirm?key=#{key}")
    |> Mailer.deliver()
  end

  @doc """
  An email with a link to reset the password.
  """
  def reset_request(address, nil) do
    prep_mail(address)
    |> subject("Recuperar contraseña")
    |> text_body(
      "You requested a password reset, but no user is associated with the email you provided."
    )
    |> Mailer.deliver()
  end

  def reset_request(address, key) do
    host = host()

    prep_mail(address)
    |> subject("Restablecer contraseña")
    |> text_body(
      "Para restablecer tu contraseña haz clic en este enlace: http://#{host}/password_resets/edit?key=#{
        key
      }"
    )
    |> Mailer.deliver()
  end

  @doc """
  An email acknowledging that the account has been successfully confirmed.
  """
  def confirm_success(address) do
    prep_mail(address)
    |> subject("Cuenta confirmada")
    |> text_body("Tu cuenta ha sido confirmada.")
    |> Mailer.deliver()
  end

  @doc """
  An email acknowledging that the password has been successfully reset.
  """
  def reset_success(address) do
    prep_mail(address)
    |> subject("Recuperar contraseña")
    |> text_body("Tu contraseña ha sido restablecida.")
    |> Mailer.deliver()
  end

  defp prep_mail(address) do
    new()
    |> to(address)
    |> from("noreply@embers.pw")
  end

  defp host do
    Application.get_env(:embers, Embers.Email)[:host]
  end
end
