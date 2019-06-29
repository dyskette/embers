import axios from "axios";
import config from "./config";
import wrap from "./wrap";

export default {
  /**
   * Get user
   * @param identifier
   */
  get(identifier) {
    return wrap(() => axios.get(`${config.prefix}/users/${identifier}`));
  },

  /**
   * Follow user
   * @param identifier
   */
  follow(id) {
    return wrap(() => axios.post(`${config.prefix}/friends`, {
      id: id
    }));
  },

  /**
   * Unfollow user
   * @param identifier
   */
  unfollow(id) {
    return wrap(() => axios.delete(`${config.prefix}/friends/${id}`));
  },

  block(id) {
    return wrap(() => axios.post(`${config.prefix}/blocks/`, {
      id: id
    }));
  },

  unblock(id) {
    return wrap(() => axios.delete(`${config.prefix}/blocks/${id}`));
  },

  /**
   * Kicks a user from the system
   * @param identifier
   */
  kick(identifier) {
    return wrap(() => axios.put(`${config.prefix}/users/${identifier}/kick`));
  },

  /**
   * Unkicks a user from the system
   * @param identifier
   */
  unkick(identifier) {
    return wrap(() =>
      axios.delete(`${config.prefix}/users/${identifier}/kick`)
    );
  },

  /**
   * Gets user mutuals
   */
  getMutuals() {
    return wrap(() =>
      axios.get(`${config.prefix}/users/${window.appData.user.id}/mutuals`)
    );
  },
  /**
   * Gets user online mutuals
   */
  getOnlineMutuals() {
    return wrap(() =>
      axios.get(
        `${config.prefix}/users/${window.appData.user.id}/mutuals/online`
      )
    );
  },

  /**
   * Gets users following user
   */
  getFollowing(params = {}) {
    let query = {};
    let id = null;

    query.before = params.before;

    query.after = params.after;

    query.limit = params.limit;

    if (!params.id) id = window.appData.user.id;
    else id = params.id;

    return wrap(() =>
      axios.get(`${config.prefix}/friends/${id}/list`, {
        query
      })
    );
  },

  /**
   * Gets users followed by user
   */
  getFollowed(params = {}) {
    let query = {};
    let id = null;

    if (!isNaN(params.before)) query.before = params.before;

    if (!isNaN(params.after)) query.after = params.after;

    if (isNaN(params.id)) id = window.appData.user.id;
    return wrap(() =>
      axios.get(`${config.prefix}/followers/${id}/list`, {
        params
      })
    );
  },

  getBlocked() {
    let id = window.appData.user.id;
    return wrap(() => axios.get(`${config.prefix}/blocks/list`));
  },

  getPasses() {
    return wrap(() => axios.get(`${config.prefix}/users/invite/passes`));
  },

  /**
   * User settings
   */
  settings: {
    /**
     * Update profile settings
     * @param settings
     */
    updateProfile(settings) {
      return wrap(() => axios.put(`${config.prefix}/account/meta`, settings));
    },

    /**
     * Update content settings
     * @param settings
     */
    updateContent(settings) {
      return wrap(() =>
        axios.put(`${config.prefix}/account/settings`, settings)
      );
    },

    /**
     * Update privacy settings
     * @param settings
     */
    updatePrivacy(settings) {
      return wrap(() =>
        axios.put(`${config.prefix}/account/settings`, settings)
      );
    },

    /**
     * Update profile picture
     * @param settings
     */
    updateAvatar(settings) {
      return wrap(() =>
        axios.post(`${config.prefix}/account/avatar`, settings)
      );
    },

    /**
     * Delete profile picture
     * @param identifier
     */
    deleteAvatar(identifier = null) {
      return wrap(() =>
        axios.delete(`${config.prefix}/account/avatar/${identifier || ""}`)
      );
    },

    /**
     * Update cover picture
     * @param settings
     */
    updateCover(settings) {
      return wrap(() => axios.post(`${config.prefix}/account/cover`, settings));
    },

    /**
     * Delete cover picture
     * @param identifier
     */
    deleteCover(identifier = null) {
      return wrap(() =>
        axios.delete(`${config.prefix}/account/cover/${identifier || ""}`)
      );
    }
  },

  /** Helper methods */
  can(...permissions) {
    if (window.appData.user === null) return false;

    for (let permission of permissions) {
      if (window.appData.user.permissions.indexOf(permission) === -1)
        return false;
    }

    return true;
  }
};
