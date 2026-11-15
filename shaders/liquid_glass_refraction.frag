// Backdrop refraction for the navigation glass.
// This samples the backdrop and bends it near the rounded rim.
// It is not Apple's Liquid Glass.
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

void main() {
  vec2 pixel = FlutterFragCoord().xy;
  vec2 uv = pixel / u_size;

  vec2 half_size = u_size * 0.5;
  vec2 p = pixel - half_size;
  float dist = rounded_box(p, half_size);
  vec2 normal = surface_normal(p, half_size);

  float short_side = max(min(u_size.x, u_size.y), 1.0);
  // The backdrop texture is the clipped glass. Sampling past its edge reads
  // empty texels, so the bend moves inward. The band is wide enough that
  // content behind the bar, not only the outline, moves.
  float band = mix(short_side * 0.22, short_side * 0.78, clamp(u_edge, 0.0, 1.0));
  float edge_weight = smoothstep(-band, -2.0, dist);
  float shift = clamp(u_refraction, 0.0, 1.0) *
      mix(6.0, min(26.0, short_side * 0.2), clamp(u_edge, 0.0, 1.0)) *
      edge_weight;

  vec2 sample_pixel = pixel - normal * shift;
  vec2 sample_uv = clamp(sample_pixel / u_size, vec2(0.02), vec2(0.98));
  vec2 raw_uv = clamp(uv, vec2(0.02), vec2(0.98));
#ifdef IMPELLER_TARGET_OPENGLES
  sample_uv.y = 1.0 - sample_uv.y;
  raw_uv.y = 1.0 - raw_uv.y;
#endif

  vec4 bent = texture(u_texture, sample_uv);
  vec4 raw = texture(u_texture, raw_uv);
  vec4 backdrop = mix(raw, bent, edge_weight * clamp(u_refraction, 0.0, 1.0));
  vec3 encoded = backdrop.rgb;
  vec3 linear = linear_from_srgb(encoded);
  float luminance = dot(linear, vec3(0.2126, 0.7152, 0.0722));
  float response = smoothstep(0.08, 0.82, luminance);
  float clear = step(0.5, u_variant);
  float veil = mix(0.10, 0.28, response) * mix(1.0, 0.38, clear);

  vec3 color;
  if (u_adaptive < 0.5) {
    color = mix(encoded, u_tint.rgb, u_tint.a * mix(0.55, 0.22, clear));
  } else {
    vec3 veil_color = mix(vec3(0.08), vec3(0.96), response);
    color = mix(encoded, veil_color, veil * 0.32);
    color = mix(color, u_tint.rgb, u_tint.a * mix(0.40, 0.16, clear));
  }

  vec2 light = u_light;
  float light_len = length(light);
  if (light_len > 0.001) {
    light /= light_len;
  } else {
    light = vec2(0.0, -1.0);
  }
  float incidence = clamp(dot(normal, light), 0.0, 1.0);
  float spec = pow(incidence, 16.0) * edge_weight *
      clamp(u_highlight, 0.0, 1.0) * 0.42;
  float top = smoothstep(0.35, 0.0, uv.y) * edge_weight * u_highlight * 0.08;
  color += vec3(spec + top);

  frag_color = vec4(color, 1.0);
}
