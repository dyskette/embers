import Config

config :embers, EmbersWeb.Gettext, default_locale: System.get_env("DEFAULT_LOCALE", "en")

config :embers, Embers.Media, bucket: System.fetch_env!("EMBERS_MEDIA_BUCKET")
config :embers, Embers.Profile, bucket: System.fetch_env!("EMBERS_PROFILE_BUCKET")
config :embers, Embers.Email, host: System.fetch_env!("EMBERS_HOST")

# Configure your database
config :embers, Embers.Repo,
  username: System.fetch_env!("DB_USER"),
  password: System.fetch_env!("DB_PWD"),
  database: System.fetch_env!("DB_NAME"),
  hostname: System.fetch_env!("DB_HOST"),
  pool_size: 10

# Configure Recaptcha
config :recaptcha,
  public_key: System.fetch_env!("RECAPTCHA_PUBLIC_KEY"),
  secret: System.fetch_env!("RECAPTCHA_SECRET")

config :ex_aws, :s3, %{
  access_key_id: System.fetch_env!("S3_ACCESS_KEY"),
  secret_access_key: System.fetch_env!("S3_SECRET"),
  scheme: "https://",
  host: System.fetch_env!("S3_HOST"),
  region: System.fetch_env!("S3_REGION")
}

config :embers, Embers.FileStorage,
  store: Embers.FileStorage.Store.S3,
  bucket: "uploads",
  schema: "https://",
  host: System.fetch_env!("S3_HOST_URL")

config :embers, EmbersWeb.Mailer,
  adapter: Swoosh.Adapters.SMTP,
  relay: System.fetch_env!("MAIL_RELAY"),
  username: System.fetch_env!("MAIL_USERNAME"),
  password: System.fetch_env!("MAIL_PASSWORD"),
  ssl: false,
  auth: :always,
  port: System.fetch_env!("MAIL_SMTP_PORT")

config :sentry,
  dsn: System.fetch_env!("SENTRY_DSN"),
  environment_name: :prod,
  enable_source_code_context: true,
  root_source_code_path: File.cwd!(),
  tags: %{
    env: "production"
  },
  included_environments: [:prod]
