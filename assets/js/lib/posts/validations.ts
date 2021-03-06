export function must_have_body(post) {
  const medias = post.medias || [];
  const links = post.links || [];
  const related = post.related_to_id;

  const is_shared = !!related;
  const has_media = medias.length > 0;
  const has_link = links.length > 0;

  if (is_shared || has_media || has_link) return false;
  return true;
}

export function valid_body(post) {
  const body = post.body;

  if (body && body.length > 1600) return false;
  if (must_have_body(post) && !body.length) return false;
  return true;
}

export function valid_tag(tag: string): boolean {
  return  tag.length > 2    &&
          tag.length < 100  &&
          /^\w+$/.test(tag)
}

export function invalid_tags(tags: string[]): string[] {
  return tags
    .filter(tag => !valid_tag(tag))
}

export function valid_post(post) {
  if (!valid_body(post)) return false;
  return true;
}
