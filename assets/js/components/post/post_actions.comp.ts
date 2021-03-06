import { html, ref } from "heresy";
import { Component } from "../component";
import { gettext } from "~js/lib/gettext";

import * as Application from "~js/lib/application";
import * as Posts from "~js/lib/posts";
import * as Timeline from "~js/lib/timeline";

import icon_gavel from "~static/svg/generic/icons/gavel.svg";
import icon_ellipsis from "~static/svg/generic/icons/ellipsis-v.svg";
import { show_reactions } from "~js/managers/post";
import { confirm } from "~js/managers/dialog";
import { ban_user_dialog } from "../moderation/ban-user-dialog.comp";
import { FetchResults } from "~js/lib/utils/fetch";
import { block_user } from "~js/lib/blocks";
import status_toasts from "~js/managers/status_toasts";

export default class PostActions extends Component(HTMLElement) {
  static component = "PostActions";

  post: HTMLElement;
  faved: boolean;
  is_owner: boolean;
  is_activity: boolean;
  post_kind: "post" | "reply";

  onconnected() {
    this.post = this.closest("article[data-author-id]") as HTMLElement;
    this.is_owner = this.post.dataset.authorId === Application.get_user().id;
    this.is_activity = !!this.post.hasAttribute("activity");
    this.faved = this.post.hasAttribute("faved");

    this.post_kind = this.post.classList.contains("reply") ? "reply" : "post";
  }

  render() {
    if (!Application.is_authenticated()) {
      this.html``;
      return;
    }

    const mod_tools = Application.can("access_mod_tools")
      ? html`
          <div class="hover-menu-wrapper">
            <button class="plain-button">${{ html: icon_gavel }}</button>
            <div class="hover-menu bottom-right">
              <ol>
                ${this.post_kind === "post"
                  ? html`
                      <li>
                        <button
                          class="plain-button"
                          data-action="click->post#toggle_nsfw"
                        >
                          <span class="is-nsfw">${gettext("Is NSFW")}</span>
                          <span class="isnt-nsfw"
                            >${gettext("Isn't NSFW")}</span
                          >
                        </button>
                      </li>
                    `
                  : ``}
                <li>
                  <button
                    class="plain-button danger"
                    onclick=${this.confirm_delete}
                  >
                    <span> ${gettext("Disable")} </span>
                  </button>
                </li>
                <li>
                  <button class="plain-button danger" onclick=${this.ask_ban}>
                    <span> ${gettext("Ban user")} </span>
                  </button>
                </li>
              </ol>
            </div>
          </div>
        `
      : ``;

    this.html`
    <div class="post-actions">
      ${mod_tools}
      ${
        this.post_kind === "post"
          ? html`
              <button
                is="post-fav-button"
                class="plain-button"
                data-post_id=${this.post.dataset.id}
              ></button>
            `
          : ``
      }
      <div class="hover-menu-wrapper">
        <button class="plain-button">
          ${{ html: icon_ellipsis }}
        </button>
        <div class="hover-menu bottom-right">
          <ol>
            <li>
              <button class="plain-button" onclick=${
                this.show_reactions_dialog
              }>
                <span>${gettext("Reactions")}</span>
              </button>
            </li>
            ${
              this.is_activity
                ? html`<li>
                    <button class="plain-button" onclick=${this.hide_activity}>
                      <span>${gettext("Hide")}</span>
                    </button>
                  </li>`
                : ``
            }
            <li>
              <button class="plain-button" onclick=${this.show_report_modal}>
                <span>${gettext("Report")}</span>
              </button>
            </li>
            <li>
              <button class="plain-button" onclick=${this.confirm_block}>
                <span>${gettext("Block")}</span>
              </button>
            </li>
            ${
              this.is_owner
                ? html`<li>
                    <button
                      class="plain-button danger"
                      onclick=${this.confirm_delete}
                    >
                      <span>${gettext("Delete")}</span>
                    </button>
                  </li> `
                : ``
            }
          </ol>
        </div>
      </div>
    </div>
    `;
  }

  show_report_modal = () => {
    window["report_post_modal"].showModal(this.post.dataset.id);
  };

  show_reactions_dialog = () => {
    show_reactions(this.post.dataset.id);
  };

  confirm_delete = () => {
    confirm({
      title: gettext("Delete post?"),
      text: gettext("This will permanently delete this post"),
    }).then((choice) => {
      if (choice) this.delete_post();
    });
  };

  delete_post = async () => {
    const res = await Posts.delet(this.post.dataset.id);
    switch (res.tag) {
      case "Success": {
        window["status_toasts"].add({ content: "Post deleted!" });
        this.post.remove();
        break;
      }
      case "Error": {
        alert("Hubo un error al borrar el post");
        break;
      }
      case "NetworkError": {
        alert("Hubo un error al conectar con el servidor");
        break;
      }
    }
  };

  confirm_block = async () => {
    const choice = await confirm({
      title: gettext("Block «@%1»", this.post.dataset.author),
      text: gettext(
        "The user won't be able to interact with you, and you won't see their posts on your timeline"
      ),
    });
    if (!choice) return;

    const result = await block_user(this.post.dataset.author);

    if (!result) {
      status_toasts.add({
        content: gettext(
          "We were unable to block the user. Please try again later."
        ),
        classes: ["error"],
      });
      return;
    }

    status_toasts.add({ content: gettext("The user was blocked.") });
  };

  ask_ban = () => {
    ban_user_dialog.showModal(this.post.dataset.author);
  };

  hide_activity = async () => {
    const res = await Timeline.hide_activity(this.post.dataset.id);
    if (res) {
      this.post.remove();
    }
  };
}
