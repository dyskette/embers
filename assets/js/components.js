import { define } from "heresy";
// @ts-ignore
import components from "./components/*/index.ts";

import PostTags from "./components/post/tags";
import PostFavButton from "./components/post/favorite-button";
import PostActions from "./components/post/post_actions";

import ENotification from "./components/notifications_panel/notification";
import NotificationsBell from "./components/notifications_panel/notifications-bell";

export function init() {
  for(let name in components) {
    define(components[name].default);
  }
  define(PostTags);
  define(PostFavButton);
  define(PostActions);

  define(ENotification);
  define(NotificationsBell);
}
