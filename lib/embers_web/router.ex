defmodule EmbersWeb.Router do
  use EmbersWeb, :router

  import Phoenix.LiveDashboard.Router

  alias EmbersWeb.Plugs.{CheckPermissions, GetPermissions}

  pipeline :browser do
    plug(:accepts, ["html", "json"])
    plug(:fetch_session)

    plug(Cldr.Plug.SetLocale,
      apps: [:cldr, :gettext],
      from: [:accept_language, :path, :query],
      gettext: EmbersWeb.Gettext,
      cldr: EmbersWeb.Cldr
    )

    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(EmbersWeb.Authenticate)
    plug(EmbersWeb.Remember)
    plug(GetPermissions)
    plug(EmbersWeb.Plugs.LoadSettings)
    plug(EmbersWeb.Plugs.SelectLayout)
    plug(EmbersWeb.Plugs.ModData)
  end

  pipeline :admin do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:put_secure_browser_headers)
    plug(EmbersWeb.Authenticate)
    plug(EmbersWeb.Remember)
    plug(GetPermissions)
    plug(CheckPermissions, permission: "access_backoffice")

    plug(:protect_from_forgery)
  end

  scope "/" do
    pipe_through([:browser, :admin])

    live_dashboard("/dashboard", ecto_repos: [Embers.Repo], metrics: EmbersWeb.Telemetry)
  end

  scope "/" do
    pipe_through(:browser)
    get("/auth_data", EmbersWeb.Api.PageController, :auth)
  end

  scope "/", EmbersWeb.Web do
    pipe_through(:browser)

    get("/", PageController, :index)

    get("/static/rules", PageController, :rules)
    get("/static/faq", PageController, :faq)
    get("/static/acknowledgments", PageController, :acknowledgments)

    # Authentication
    get("/login", SessionController, :new)
    post("/login", SessionController, :create)
    delete("/sessions", SessionController, :delete)
    get("/confirm", ConfirmController, :index)

    # Password reset
    get("/password_resets/new", PasswordResetController, :new)
    post("/password_resets/new", PasswordResetController, :create)
    get("/password_resets/edit", PasswordResetController, :edit)
    put("/password_resets/edit", PasswordResetController, :update)

    # Account creation
    get("/register", AccountController, :new)
    post("/register", AccountController, :create)

    # Settings
    scope "/settings" do
      get("/", SettingsController, :show_profile)
      patch("/", SettingsController, :update)
      post("/reset_pass", SettingsController, :reset_pass)
      get("/profile", SettingsController, :show_profile)
      patch("/profile/update_profile", SettingsController, :update_profile)
      post("/profile/update_cover", SettingsController, :update_cover)
      post("/profile/update_avatar", SettingsController, :update_avatar)
      get("/content", SettingsController, :show_content)
      get("/design", SettingsController, :show_design)
      get("/privacy", SettingsController, :show_privacy)
      get("/security", SettingsController, :show_security)
    end

    # Feeds
    get("/timeline", TimelineController, :index)
    delete("/timeline/activity/:id", TimelineController, :hide_activity)
    get("/discover", DiscoverController, :index)

    # User profile
    get("/user/:user_id/timeline", UserController, :timeline)
    get("/@:username", UserController, :show)
    get("/@:username/followers", UserController, :show_followers)
    get("/@:username/following", UserController, :show_following)
    get("/@:username/card", UserController, :show_card)

    # Posts
    scope "/post" do
      post("/", PostController, :create)
      delete("/:id", PostController, :delete)
      get("/:hash", PostController, :show)
      get("/:hash/modal", PostController, :show_modal)

      # Post replies
      get("/:hash/replies", PostController, :show_replies)
      # Post Reactions
      post("/:hash/reactions", PostController, :add_reaction)
      delete("/:hash/reactions/:name", PostController, :remove_reaction)

      get("/:hash/reactions/overview", ReactionController, :reactions_overview)
      get("/:hash/reactions/:reaction_name", ReactionController, :reactions_by_name)
    end

    # Medias
    post("/medias", MediaController, :upload)

    # Links
    post("/links", LinkController, :process)

    # Favorites
    get("/favorites", FavoriteController, :list)
    post("/favorites/:post_id", FavoriteController, :create)
    delete("/favorites/:post_id", FavoriteController, :destroy)

    # Notifications
    get("/notifications", NotificationController, :index)
    put("/notifications/:id", NotificationController, :read)

    # Follows
    post("/user_follow", UserFollowController, :create)
    post("/user_follow/name", UserFollowController, :create_by_name)
    delete("/user_follow/:id", UserFollowController, :destroy)
    delete("/user_follow/name/:name", UserFollowController, :destroy_by_name)

    # Chat
    scope "/chat" do
      get("/", ChatController, :index)
      post("/", ChatController, :create)
      get("/conversations", ChatController, :list_conversations)
      get("/@:username", ChatController, :show)
      get("/:id/messages", ChatController, :show_messages)
      put("/:id", ChatController, :read)
    end

    # Tags
    get("/tag/:name", TagController, :show)
    put("/tag/:id", TagController, :update)

    get("/tags/popular", TagController, :list_popular)
    get("/tags/pinned", TagPinnedController, :list_pinned)

    # Tags subscriptions
    post("/tags/:tag_id/sub", TagSubscriptionController, :subscribe)
    delete("/tags/:tag_id/sub", TagSubscriptionController, :unsubscribe)

    # Search
    get("/search/:query", SearchController, :search)
    get("/search_typeahead/user/:username", SearchController, :user_typeahead)

    # Reports
    post("/reports/post/:post_id", ReportController, :create_post_report)

    # Subscriptions
    scope "/subs" do
      get("/", TagSubscriptionController, :index)
      get("/tags", TagSubscriptionController, :index)
    end

    # Blocks
    scope "/blocks" do
      get("/", BlockController, :index)
      post("/", BlockController, :create)
      delete("/:id", BlockController, :destroy)
    end

    scope "/moderation", Moderation do
      pipe_through(:admin)

      # Dashboard
      get("/", DashboardController, :index)

      # Audit
      get("/audit", AuditController, :index)

      # Bans
      get("/bans", BanController, :index)
      post("/bans/unban", BanController, :unban)
      post("/ban/user/:canonical", BanController, :ban)

      # Posts
      post("/post/update_tags", TagController, :update_tags)

      # Disabled posts
      get("/disabled_posts", DisabledPostController, :index)
      put("/disabled_posts/:post_id/restore", DisabledPostController, :restore)

      # Reports
      get("/reports", ReportsController, :index)
      put("/reports/post/:post_id", ReportsController, :resolve)

      put(
        "/reports/post/:post_id/nsfw_and_resolve",
        ReportsController,
        :mark_post_nsfw_and_resolve
      )

      put(
        "/reports/post/:post_id/disable_and_resolve",
        ReportsController,
        :disable_post_and_resolve
      )

      get("/reports/post/:post_id/comments", ReportsController, :show_comments)

      # Users
      get("/users", UserController, :index)
      get("/users/list.json", UserController, :list_users)
      put("/users/:user_id", UserController, :update)
      delete("/users/:user_id/avatar", UserController, :remove_avatar)
      delete("/users/:user_id/cover", UserController, :remove_cover)

      # Roles
      get("/roles", RoleController, :index)
      put("/roles/:role_id", RoleController, :update)
    end
  end

  scope "/api/v1", EmbersWeb.Api, as: :api do
    pipe_through(:browser)
    # should be deprecated?
    # post("/auth",SessionController, :create_api)

    # User
    get("/users/:id", UserController, :show)

    # Account settings
    put("/account/meta", MetaController, :update)
    post("/account/avatar", MetaController, :upload_avatar)
    post("/account/cover", MetaController, :upload_cover)
    put("/account/settings", SettingController, :update)
    post("/account/reset_pass", UserController, :reset_pass)

    # Mod specific routes
    # TODO move to an admin protected scope
    post("/moderation/ban", ModerationController, :ban_user)
    post("/moderation/post/update_tags", ModerationController, :update_tags)

    post("/friends", FriendController, :create)
    post("/friends/name", FriendController, :create_by_name)
    delete("/friends/:id", FriendController, :destroy)
    delete("/friends/name/:name", FriendController, :destroy_by_name)

    get("/blocks/ids", BlockController, :list_ids)
    get("/blocks/list", BlockController, :list)
    post("/blocks", BlockController, :create)
    delete("/blocks/:id", BlockController, :destroy)

    get("/tag_blocks/ids", TagBlockController, :list_ids)
    get("/tag_blocks/list", TagBlockController, :list)
    post("/tag_blocks", TagBlockController, :create)
    delete("/tag_blocks/:id", TagBlockController, :destroy)

    get("/tags/popular", TagController, :popular)
    get("/tags/hot", TagController, :hot)

    get("/subscriptions/tags/ids", TagController, :list_ids)
    get("/subscriptions/tags/list", TagController, :list)
    post("/subscriptions/tags", TagController, :create)
    delete("/subscriptions/tags/:id", TagController, :destroy)

    get("/tags/:name", TagController, :show_tag)
    get("/tags/:name/posts", TagController, :show_tag_posts)

    get("/following/:id/ids", FriendController, :list_ids)
    get("/following/:id/list", FriendController, :list)
    get("/followers/:id/ids", FriendController, :list_followers_ids)
    get("/followers/:id/list", FriendController, :list_followers)

    resources("/posts", PostController, only: [:show, :create, :delete])
    get("/posts/:id/replies", PostController, :show_replies)
    post("/posts/:post_id/reaction/:name", ReactionController, :create)
    delete("/posts/:post_id/reaction/:name", ReactionController, :delete)
    post("/posts/:post_id/report", PostReportController, :create)

    get(
      "/posts/:post_id/reactions/overview",
      ReactionController,
      :reactions_overview
    )

    get(
      "/posts/:post_id/reactions/:reaction_name",
      ReactionController,
      :reactions_by_name
    )

    get("/reactions/valid", ReactionController, :list_valid_reactions)

    get("/feed", FeedController, :timeline)
    get("/feed/public", FeedController, :get_public_feed)
    get("/feed/user/:id", FeedController, :user_statuses)
    delete("/feed/activity/:id", FeedController, :hide_post)

    get("/feed/favorites", FavoriteController, :list)
    post("/feed/favorites/:post_id", FavoriteController, :create)
    delete("/feed/favorites/:post_id", FavoriteController, :destroy)

    post("/media", MediaController, :upload)
    post("/link", LinkController, :parse)

    get("/notifications", NotificationController, :index)
    put("/notifications/:id", NotificationController, :read)

    get("/search/:query", SearchController, :search)
    get("/search_typeahead/user/:username", SearchController, :user_typeahead)

    get("/chat/conversations", ChatController, :list_conversations)
    post("/chat/conversations", ChatController, :create)
    get("/chat/conversations/:id", ChatController, :list_messages)
    put("/chat/conversations/:id", ChatController, :read)
    get("/chat/unread", ChatController, :list_unread_conversations)
  end
end
