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
  // Outward bend. The backdrop texture is only this clipped rect, so the
  // sample is clamped inside it. A sample past the edge is empty, not page.
  // Clear reaches farther. Regular stays shorter so the center stays readable.
  float clear = step(0.5, u_variant);
  float band = mix(short_side * 0.16, short_side * 0.48, clamp(u_edge, 0.0, 1.0));
  float edge_weight = smoothstep(-band, -1.0, dist);
  float reach = mix(0.20, 0.36, clear);
  float shift = min(
    short_side * 0.22,
    clamp(u_refraction, 0.0, 1.0) * short_side * reach * edge_weight
  );
  vec2 sample_pixel = clamp(pixel + normal * shift, vec2(1.0), u_size - vec2(1.0));
  vec2 sample_uv = sample_pixel / u_size;
  vec2 raw_uv = clamp(uv, vec2(0.001), vec2(0.999));
#ifdef IMPELLER_TARGET_OPENGLES
  sample_uv.y = 1.0 - sample_uv.y;
  raw_uv.y = 1.0 - raw_uv.y;
#endif

  vec4 bent = texture(u_texture, sample_uv);
  vec4 raw = texture(u_texture, raw_uv);
  // Center stays on the unshifted pixel. The rim uses the bent sample.
  vec4 backdrop = mix(raw, bent, smoothstep(0.05, 0.85, edge_weight));
  vec3 encoded = backdrop.rgb;
  vec3 linear = linear_from_srgb(encoded);
  float luminance = dot(linear, vec3(0.2126, 0.7152, 0.0722));
  float response = smoothstep(0.05, 0.9, luminance);
  // Regular holds a veil so labels stay readable. Clear does not.
  float veil = mix(0.30, 0.0, clear);

  vec3 color = encoded;
  if (u_adaptive < 0.5) {
    color = mix(encoded, u_tint.rgb, u_tint.a * mix(0.34, 0.1, clear));
  } else {
    vec3 veil_color = mix(vec3(0.06), vec3(0.98), response);
    color = mix(encoded, veil_color, veil);
    color = mix(color, u_tint.rgb, u_tint.a * mix(0.28, 0.05, clear));
  }

  vec2 light = u_light;
  float light_len = length(light);
  if (light_len > 0.001) {
    light /= light_len;
  } else {
    light = vec2(-0.15, -1.0);
  }
  float incidence = clamp(dot(normal, light), 0.0, 1.0);
  float fresnel = pow(clamp(edge_weight, 0.0, 1.0), 1.8);
  float spec = pow(incidence, 32.0) * fresnel *
      clamp(u_highlight, 0.0, 1.0) * mix(0.28, 0.14, clear);
  color = clamp(color + vec3(spec), 0.0, 1.0);

  frag_color = vec4(color, 1.0);
}
