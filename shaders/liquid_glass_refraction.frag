// Backdrop lens clipped to the painted glass.
// One displaced sample, then a tight blur around that same point.
// Wide taps and a second displaced copy repeat glyphs, so they are not used.
// The backdrop texture is only the clipped shape. This is not Apple's Liquid Glass.
#include <flutter/runtime_effect.glsl>

uniform vec2 u_size;
uniform sampler2D u_texture;

uniform float u_radius_tl;
uniform float u_radius_tr;
uniform float u_radius_br;
uniform float u_radius_bl;
uniform float u_refraction;
uniform float u_edge;
uniform float u_highlight;
uniform vec4 u_tint;
uniform float u_variant;
uniform float u_adaptive;
uniform vec2 u_light;

out vec4 frag_color;

float corner_radius(vec2 p) {
  if (p.x < 0.0) {
    return p.y < 0.0 ? u_radius_tl : u_radius_bl;
  }
  return p.y < 0.0 ? u_radius_tr : u_radius_br;
}

float rounded_box(vec2 p, vec2 half_size) {
  float radius = min(corner_radius(p), min(half_size.x, half_size.y));
  vec2 q = abs(p) - half_size + vec2(radius);
  return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - radius;
}

// Y grows downward, so a flat top edge returns (0, -1).
vec2 surface_normal(vec2 p, vec2 half_size) {
  const float delta = 1.0;
  float dx = rounded_box(p + vec2(delta, 0.0), half_size) -
      rounded_box(p - vec2(delta, 0.0), half_size);
  float dy = rounded_box(p + vec2(0.0, delta), half_size) -
      rounded_box(p - vec2(0.0, delta), half_size);
  float len = length(vec2(dx, dy));
  if (len < 0.0001) {
    return vec2(0.0, -1.0);
  }
  return vec2(dx, dy) / len;
}

vec2 sample_uv(vec2 pixel) {
  vec2 uv = clamp(pixel / u_size, vec2(0.001), vec2(0.999));
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif
  return uv;
}

void main() {
  vec2 pixel = FlutterFragCoord().xy;
  vec2 half_size = u_size * 0.5;
  vec2 p = pixel - half_size;
  float dist = rounded_box(p, half_size);
  vec2 normal = surface_normal(p, half_size);

  float short_side = max(min(u_size.x, u_size.y), 1.0);
  float clear = step(0.5, u_variant);
  float edge = clamp(u_edge, 0.0, 1.0);
  float refraction = clamp(u_refraction, 0.0, 1.0);
  // The bend peaks inside the rim and returns to zero on the contour, so
  // the sample does not stick to the border texel. One image, no second copy.
  float band = mix(short_side * 0.16, short_side * 0.32, edge);
  float edge_weight = smoothstep(-band, -1.0, dist);
  float depth = clamp(-dist / max(band, 1.0), 0.0, 1.0);
  float lens = sin(depth * 3.14159265);
  float shift = lens * refraction * mix(12.0, 22.0, edge) * mix(1.0, 1.28, clear);
  shift = min(shift, max(-dist - 1.5, 0.0));
  vec2 limit = u_size - vec2(1.0);
  vec2 bent_px = clamp(pixel + normal * shift, vec2(1.0), limit);

  // Five taps on the same point. Wide enough to soften a line of type,
  // close enough that the taps cannot form a second copy of a word.
  float radius = mix(8.5, 3.8, clear);
  vec3 bent = texture(u_texture, sample_uv(bent_px)).rgb;
  vec3 soft = bent * 0.36;
  soft += texture(u_texture, sample_uv(bent_px + vec2(radius, 0.0))).rgb * 0.16;
  soft += texture(u_texture, sample_uv(bent_px + vec2(-radius, 0.0))).rgb * 0.16;
  soft += texture(u_texture, sample_uv(bent_px + vec2(0.0, radius))).rgb * 0.16;
  soft += texture(u_texture, sample_uv(bent_px + vec2(0.0, -radius))).rgb * 0.16;

  float interior = 1.0 - smoothstep(0.2, 0.92, edge_weight);
  vec3 encoded = mix(bent, soft, interior * mix(0.72, 0.32, clear));

  // Keep the sampled color. A luminance veil is what turned the bar gray.
  float tint_mix = u_tint.a * mix(0.18, 0.05, clear);
  if (u_adaptive < 0.5) {
    tint_mix = u_tint.a * mix(0.24, 0.08, clear);
  }
  vec3 color = mix(encoded, u_tint.rgb, tint_mix);

  vec2 light = u_light;
  if (length(light) > 0.001) {
    light = normalize(light);
  } else {
    light = vec2(-0.15, -1.0);
  }
  float incidence = clamp(dot(normal, light), 0.0, 1.0);
  float fresnel = pow(max(edge_weight, 0.0), 1.55);
  float highlight = clamp(u_highlight, 0.0, 1.0);
  float spec = pow(incidence, 22.0) * fresnel * highlight * mix(0.34, 0.16, clear);
  spec += clamp(normal.y, 0.0, 1.0) * fresnel * highlight * mix(0.12, 0.06, clear);
  color = clamp(color + vec3(spec), 0.0, 1.0);
  frag_color = vec4(color, 1.0);
}
