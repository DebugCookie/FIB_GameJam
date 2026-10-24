shader_type spatial;
render_mode unshaded, fog_disabled;

uniform vec4 albedo: source_color; 
uniform float multiplier = 1.0; // Vignette Strength
uniform float softness = 1.0; // Vignett softness transition


const vec2 target_resolution = vec2(700.0, 350.0);
// This part affects the resolution of the pixels

const float colors_per_channel = 80.0;
// The number shows possible values for RGB

const float dither_strength = 1.0;
// This part affects dithering streght

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;
uniform sampler2D normal_texture : hint_normal_roughness_texture, filter_nearest;

void vertex() {
    POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

vec3 get_normal(vec2 uv) {
    return texture(normal_texture, uv).rgb;
}

float get_linear_depth(vec2 uv, mat4 inv_proj_mat) {
    float depth = texture(depth_texture, uv).r;
    vec3 ndc = vec3(uv * 2.0 - 1.0, depth);
    vec4 view = inv_proj_mat * vec4(ndc, 1.0);
    view.xyz /= view.w;
    return -view.z;
}

float get_dither(vec2 pos) {
    int x = int(mod(pos.x, 3.0));
    int y = int(mod(pos.y, 3.0));
	// Dithering pattern 

    int bayer[16] = {
         0,  8,  2, 10,
        12,  4, 14,  6,
         3, 11,  1,  9,
        15,  7, 13,  5
    };

    return (float(bayer[y * 4 + x]) / 16.0) - 0.5;
}

void fragment() {
    vec2 uv = floor(SCREEN_UV * target_resolution) / target_resolution;

vec2 vignette_uv = SCREEN_UV - vec2(0.5);
vignette_uv.x *= VIEWPORT_SIZE.x / VIEWPORT_SIZE.y;

float value = length(vignette_uv);

float vignette = smoothstep(
    multiplier,
    multiplier + softness,
    value
);

float vignette_effect = 1.0 - vignette;

    vec2 uvs[5] = {
        uv,
        uv + vec2(0.0, 1.0) / target_resolution, // Up
        uv - vec2(0.0, 1.0) / target_resolution, // Down
        uv + vec2(1.0, 0.0) / target_resolution, // Left
        uv - vec2(1.0, 0.0) / target_resolution  // Right
    };

    float dc = get_linear_depth(uvs[0], INV_PROJECTION_MATRIX);
    float du = get_linear_depth(uvs[1], INV_PROJECTION_MATRIX);
    float dd = get_linear_depth(uvs[2], INV_PROJECTION_MATRIX);
    float dl = get_linear_depth(uvs[3], INV_PROJECTION_MATRIX);
    float dr = get_linear_depth(uvs[4], INV_PROJECTION_MATRIX);

    float h_depth = max(0.0, dl - dc) + max(0.0, dr - dc);
    float v_depth = max(0.0, du - dc) + max(0.0, dd - dc);

    float h_outline = step(0.1, h_depth) * step(4.0, distance(dl, dr));
    float v_outline = step(0.1, v_depth) * step(4.0, distance(du, dd));

    float depth_outline = 1.0 - step(0.1, h_outline + v_outline) * 0.9;
    // Last number affects the outlines opacity

    vec3 nc = get_normal(uvs[0]);
    vec3 nu = get_normal(uvs[1]);
    vec3 nd = get_normal(uvs[2]);
    vec3 nl = get_normal(uvs[3]);
    vec3 nr = get_normal(uvs[4]);

    float nu_difference = distance(nc, nu) * max(0.0, 1.0 - distance(du, dc));
    float nd_difference = distance(nc, nd) * max(0.0, 1.0 - distance(dd, dc));
    float nl_difference = distance(nc, nl) * max(0.0, 1.0 - distance(dl, dc));
    float nr_difference = distance(nc, nr) * max(0.0, 1.0 - distance(dr, dc));

    float h_inline = step(0.2, nl_difference + nr_difference);
    float v_inline = step(0.2, nu_difference + nd_difference);

    float normal_outline = step(0.1, h_inline + v_inline) * 0.5;
    // Last number affects the highlight opacity

    vec3 color = texture(screen_texture, uv).rgb;

    vec2 pixel_pos = floor(SCREEN_UV * target_resolution);
    float dither = get_dither(pixel_pos);

    vec3 dithered_color = color
        + vec3(dither * dither_strength / colors_per_channel);

    vec3 quantized_color = floor(
        clamp(dithered_color, 0.0, 1.0) * colors_per_channel
    ) / colors_per_channel;

   
ALBEDO = quantized_color * depth_outline
    * (1.0 + normal_outline) * vignette_effect;
	 // Final color with depth outlines, normal highlights and vignette
}