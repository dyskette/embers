import { Component } from "../component";

import { add_to_favorites, remove_from_favorites } from "~js/lib/posts";

import star_outline from "/static/svg/generic/icons/star_outline.svg";
import star_filled from "/static/svg/generic/icons/star.svg";

enum States {Idle, Pending}

export default class PostFavButton extends Component(HTMLButtonElement) {
  static tagName = "button";

  static booleanAttributes = ["faved"];
  static mappedAttributes = ["faved", "state"];

  state = States.Idle;
  faved

  oninit() {
    const onclick = () => {
      switch(this.state) {
        case States.Idle: {
          this.toggle_favorite()
        }
        case States.Idle: {}
      }
    }
    this.addEventListener("click", onclick);
  }

  async toggle_favorite() {
    this.state = States.Pending;

    const post_id = this.dataset.post_id;

    let action = add_to_favorites;
    if(this.faved)
      action = remove_from_favorites;

    const res = await action(post_id);
    switch(res.tag) {
      case "Success": {
        this._toggle_state()
      }
      case "Error":
      case "NetworkError": {}
    }
  }

  _toggle_state() {
    this.state = States.Idle;
    this.faved = !this.faved;
  }

  onfaved() {
    this.render();
  }

  onstate() {
    switch(this.state) {
      case States.Idle: {
        this.removeAttribute("disabled")
      }
      case States.Pending: {
        this.setAttribute("disabled", "true")
      }
    }
  }

  render() {
    this.html`
      ${{html: this.faved ? star_filled : star_outline}}
    `
  }
}
