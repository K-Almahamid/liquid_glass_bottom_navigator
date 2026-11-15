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
  // Narrow band. The shift stays a few pixels so the map does not fold.
  float band = mix(short_side * 0.07, short_side * 0.16, edge);
  float edge_weight = smoothstep(-band, -1.0, dist);
  float shift = edge_weight * refraction * mix(3.5, 6.5, edge) * mix(1.0, 1.2, clear);
  vec2 limit = u_size - vec2(1.0);
  vec2 bent_px = clamp(pixel + normal * shift, vec2(1.0), limit);

  // Five taps on the same displaced point. A 3px radius softens a stroke
  // without placing a second copy of the word.
  float radius = mix(3.2, 1.6, clear);
  vec3 bent = texture(u_texture, sample_uv(bent_px)).rgb;
  vec3 soft = bent * 0.44;
  soft += texture(u_texture, sample_uv(bent_px + vec2(radius, 0.0))).rgb * 0.14;
  soft += texture(u_texture, sample_uv(bent_px + vec2(-radius, 0.0))).rgb * 0.14;
  soft += texture(u_texture, sample_uv(bent_px + vec2(0.0, radius))).rgb * 0.14;
  soft += texture(u_texture, sample_uv(bent_px + vec2(0.0, -radius))).rgb * 0.14;

  float interior = 1.0 - smoothstep(0.0, 0.85, edge_weight);
  vec3 encoded = mix(bent, soft, interior * mix(0.82, 0.38, clear));

  vec3 color = encoded;
  float veil = mix(0.24, 0.08, clear);
  if (u_adaptive < 0.5) {
    color = mix(encoded, u_tint.rgb, u_tint.a * mix(0.34, 0.12, clear));
  } else {
    float luma = dot(encoded, vec3(0.2126, 0.7152, 0.0722));
    vec3 haze = mix(vec3(0.93), vec3(0.14), smoothstep(0.15, 0.85, luma));
    color = mix(encoded, haze, veil);
    color = mix(color, u_tint.rgb, u_tint.a * mix(0.30, 0.08, clear));
  }

  vec2 light = u_light;
  if (length(light) > 0.001) {
    light = normalize(light);
  } else {
    light = vec2(-0.15, -1.0);
  }
  float incidence = clamp(dot(normal, light), 0.0, 1.0);
  float fresnel = pow(max(edge_weight, 0.0), 1.8);
  float highlight = clamp(u_highlight, 0.0, 1.0);
  float spec = pow(incidence, 28.0) * fresnel * highlight * mix(0.16, 0.08, clear);
  spec += clamp(normal.y, 0.0, 1.0) * fresnel * highlight * 0.04;
  color = clamp(color + vec3(spec), 0.0, 1.0);
  frag_color = vec4(color, 1.0);
}
