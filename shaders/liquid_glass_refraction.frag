// Backdrop lens for the navigation glass.
// The paint path snapshots a margin of real backdrop around the shape.
// Pixels outside the glass are discarded, so the painted bar does not grow.
// Interior taps soften text. The rim keeps a sharper, bent sample.
// This is not Apple's Liquid Glass.
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
uniform float u_inset;

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

// Finite difference. Y grows downward, so a flat top edge returns (0, -1).
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

vec3 linear_from_srgb(vec3 encoded) {
  return pow(max(encoded, vec3(0.0)), vec3(2.2));
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
  float inset = max(u_inset, 0.0);
  vec2 glass_size = max(u_size - vec2(inset * 2.0), vec2(1.0));
  vec2 half_size = glass_size * 0.5;
  vec2 p = pixel - vec2(inset) - half_size;
  float dist = rounded_box(p, half_size);
  vec3 color = vec3(0.0);
  float alpha = 0.0;
  // The margin exists so the rim can read real page pixels. It is not glass.
  if (dist <= 0.0) {
  vec2 normal = surface_normal(p, half_size);
  float short_side = max(min(glass_size.x, glass_size.y), 1.0);
  float clear = step(0.5, u_variant);
  float edge = clamp(u_edge, 0.0, 1.0);
  float refraction = clamp(u_refraction, 0.0, 1.0);
  // A thin band. Weight follows the full normal, so corners do not seam.
  float band = mix(short_side * 0.10, short_side * 0.24, edge);
  float edge_weight = smoothstep(-band, -0.5, dist);
  float curve = pow(max(edge_weight, 0.0), 0.55);
  // Prefer the painted margin. If it is missing, stay a short step inside.
  float room = max(inset, short_side * 0.16);
  float shift = curve * mix(0.34, 0.70, refraction) * room * mix(0.72, 0.92, clear);
  float limit = max(inset - 1.5, 0.0) * 0.62 + short_side * 0.02;
  shift = min(shift, max(limit, 1.0));

  vec2 edge_limit = u_size - vec2(1.0);
  vec2 bent_px = clamp(pixel + normal * shift, vec2(1.0), edge_limit);
  vec2 fold_px = clamp(pixel + normal * shift * 0.36, vec2(1.0), edge_limit);
  vec2 pulled_px = clamp(pixel - normal * shift * 0.42, vec2(1.0), edge_limit);

  vec3 raw = texture(u_texture, sample_uv(pixel)).rgb;
  vec3 bent = texture(u_texture, sample_uv(bent_px)).rgb;
  vec3 fold = texture(u_texture, sample_uv(fold_px)).rgb;
  vec3 pulled = texture(u_texture, sample_uv(pulled_px)).rgb;

  // Two rings of taps. Wide enough to soften a line of text, not the rim.
  float radius = mix(22.0, 9.0, clear);
  float half_radius = radius * 0.5;
  vec3 soft = raw * 0.20;
  soft += texture(u_texture, sample_uv(pixel + vec2(radius, 0.0))).rgb * 0.10;
  soft += texture(u_texture, sample_uv(pixel + vec2(-radius, 0.0))).rgb * 0.10;
  soft += texture(u_texture, sample_uv(pixel + vec2(0.0, radius))).rgb * 0.10;
  soft += texture(u_texture, sample_uv(pixel + vec2(0.0, -radius))).rgb * 0.10;
  soft += texture(u_texture, sample_uv(pixel + vec2(half_radius, 0.0))).rgb * 0.10;
  soft += texture(u_texture, sample_uv(pixel + vec2(-half_radius, 0.0))).rgb * 0.10;
  soft += texture(u_texture, sample_uv(pixel + vec2(0.0, half_radius))).rgb * 0.10;
  soft += texture(u_texture, sample_uv(pixel + vec2(0.0, -half_radius))).rgb * 0.10;

  vec3 rim = mix(bent, pulled, 0.12);
  vec3 lens = mix(raw, rim, smoothstep(0.04, 0.92, edge_weight));
  float reflect_w = smoothstep(0.78, 1.0, edge_weight) * mix(0.12, 0.20, clear);
  lens = mix(lens, fold, reflect_w);

  float interior = 1.0 - smoothstep(0.12, 0.82, edge_weight);
  float haze = interior * mix(0.90, 0.46, clear);
  vec3 encoded = mix(lens, soft, haze);

  vec3 linear = linear_from_srgb(encoded);
  float luminance = dot(linear, vec3(0.2126, 0.7152, 0.0722));
  float response = smoothstep(0.05, 0.9, luminance);
  float veil = mix(0.55, 0.18, clear) * mix(0.28, 1.0, interior);

  color = encoded;
  if (u_adaptive < 0.5) {
    color = mix(encoded, u_tint.rgb, u_tint.a * mix(0.40, 0.14, clear));
  } else {
    vec3 veil_color = mix(vec3(0.07), vec3(0.97), response);
    color = mix(encoded, veil_color, veil);
    color = mix(color, u_tint.rgb, u_tint.a * mix(0.36, 0.10, clear) * mix(0.55, 1.0, interior));
  }

  vec2 light = u_light;
  float light_len = length(light);
  if (light_len > 0.001) {
    light /= light_len;
  } else {
    light = vec2(-0.15, -1.0);
  }
  float incidence = clamp(dot(normal, light), 0.0, 1.0);
  float fresnel = pow(max(edge_weight, 0.0), 1.65);
  float vertical = abs(normal.y);
  float highlight = clamp(u_highlight, 0.0, 1.0);
  float spec = pow(incidence, 28.0) * fresnel * highlight *
      mix(0.22, 0.11, clear) * mix(0.62, 1.0, vertical);
  // The light faces up, so the bottom rim would otherwise stay dark.
  spec += clamp(normal.y, 0.0, 1.0) * fresnel * highlight * mix(0.06, 0.04, clear);
  color = clamp(color + vec3(spec), 0.0, 1.0);
  alpha = 1.0;
  }

  frag_color = vec4(color, alpha);
}
