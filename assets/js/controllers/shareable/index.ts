import { BaseController } from "~js/lib/controller";
import type SharePostDialog from "~js/components/share_post_dialog/share_post_dialog.comp";

export const name = "shareable"

export default class extends BaseController {
  static targets = ["dialog"];

  showDialog() {
    this.get_target<SharePostDialog>("dialog").showModal();
  }
}
