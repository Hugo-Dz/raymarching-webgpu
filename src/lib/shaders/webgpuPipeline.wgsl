// Structs
struct VsOut {
    @builtin(position) position: vec4f,
    @location(0) uv: vec2f,
};

struct Uniforms {
    mouse_down: f32,
    smooth_value: f32,
    time: f32,
    aspect_ratio: f32,
    camera_position: vec4<f32>,
    shape_1: f32,
    shape_2: f32,
    operation: f32,
};

// Constants
const START: f32 = 0.1;
const END: f32 = 100.0;
const MAX_STEPS: i32 = 100;
const EPSILON: f32 = 0.001;

// Enums
const SHAPE_SPHERE: i32 = 0;
const SHAPE_TORUS: i32 = 1;
const SHAPE_BOX: i32 = 2;
const SHAPE_BOX_FRAME: i32 = 3;
const SHAPE_GYROID: i32 = 4;
const OP_UNION: i32 = 0;
const OP_INTERSECT: i32 = 1;
const OP_SUBTRACT: i32 = 2;

@binding(0) @group(0) var<uniform> uniforms: Uniforms;

@vertex fn vertex_shader(@builtin(vertex_index) vertexIndex: u32) -> VsOut {
    var vsOut: VsOut;
    // 2-triangles screen space
    let pos = array(
        vec2f(-1.0, -1.0),  // Triangle 1
        vec2f( 1.0, -1.0),
        vec2f(-1.0,  1.0),
        vec2f(-1.0,  1.0),  // Triangle 2
        vec2f( 1.0, -1.0),
        vec2f( 1.0,  1.0)
    );
    let uv = array(
        vec2f(0.0, 0.0),  // Triangle 1
        vec2f(1.0, 0.0),
        vec2f(0.0, 1.0),
        vec2f(0.0, 1.0),  // Triangle 2
        vec2f(1.0, 0.0),
        vec2f(1.0, 1.0)
    );
    vsOut.uv = uv[vertexIndex];
    vsOut.position = vec4f(pos[vertexIndex], 0.0, 1.0);

    return vsOut;
}

@fragment fn fragment_shader(v: VsOut) -> @location(0) vec4f {

    let plane_size: vec2f = vec2f(8.0, 8.0 / uniforms.aspect_ratio);
    
    let corrected_uv: vec2f = (v.uv - 0.5) * vec2f(plane_size.x / 2, plane_size.y / 2);
    let camera_target: vec3f = vec3f(0.0, 0.0, 0.0);
    let up_vector: vec3f = vec3f(0.0, 1.0, 0.0); 

    let view_mat: mat4x4<f32> = viewMatrix(uniforms.camera_position.xyz, camera_target, up_vector);
    let ray_origin: vec3<f32> = uniforms.camera_position.xyz;
    let initial_ray_dir: vec3<f32> = normalize(vec3<f32>(corrected_uv, -3.5));
    let ray_dir: vec3<f32> = (view_mat * vec4<f32>(initial_ray_dir, 0.0)).xyz;

    let normal: vec3<f32> = rayMarch(ray_origin, ray_dir);

    return vec4f(normal.x, normal.y, normal.z, 1.0);
}

fn rayMarch(origin: vec3f, direction: vec3f) -> vec3f {
    var depth: f32 = START;
    for (var i: i32 = 0; i < MAX_STEPS; i++) {
        let point: vec3f = origin + depth * direction;
        let dist: f32 = sceneSDF(point);
        if (dist < EPSILON) {
            return estimateNormal(point, EPSILON);
        }
        depth += dist;
        if (depth >= END) {
            break;
        }
    }
    return vec3f(0.0, 0.0, 0.0);
}

fn estimateNormal(p: vec3f, epsilon: f32) -> vec3f {
    let normal: vec3f = vec3f(
        sceneSDF(p + vec3f(epsilon, 0.0, 0.0)) - sceneSDF(p - vec3f(epsilon, 0.0, 0.0)),
        sceneSDF(p + vec3f(0.0, epsilon, 0.0)) - sceneSDF(p - vec3f(0.0, epsilon, 0.0)),
        sceneSDF(p + vec3f(0.0, 0.0, epsilon)) - sceneSDF(p - vec3f(0.0, 0.0, epsilon))
    );
    return normalize(normal);
}

fn sceneSDF(p: vec3f) -> f32 {
    let animated_x = 2 * sin(uniforms.time);
    let shape_1_center = vec3<f32>(animated_x, 0.0, 0.0);
    let shape_2_center = vec3<f32>(0.0, 0.0, 0.0);

    let shape_1_type = i32(uniforms.shape_1);
    let shape_2_type = i32(uniforms.shape_2);
    let operation_type = i32(uniforms.operation);

    let d1 = getShapeSDF(shape_1_type, p - shape_1_center);
    let d2 = getShapeSDF(shape_2_type, p - shape_2_center);

    switch operation_type {
        case OP_UNION: {
            return unionSDF(d1, d2, uniforms.smooth_value);
        }
        case OP_INTERSECT: {
            return intersectSDF(d1, d2, uniforms.smooth_value);
        }
        default: {
            return subtractSDF(d1, d2, uniforms.smooth_value);
        }
    }
}

fn getShapeSDF(shape_type: i32, center: vec3f) -> f32 {
    switch shape_type {
        case SHAPE_SPHERE: {
            return sphereSDF(center);
        }
        case SHAPE_TORUS: {
            return torusSDF(center, 1.3, 0.1);
        }
        case SHAPE_BOX: {
            return roundBoxSDF(center, vec3f(0.5, 0.5, 0.5), 0.04);
        }
        case SHAPE_BOX_FRAME: {
            return BoxFrameSDF(center, vec3f(0.5, 0.5, 0.5), 0.04, 0.02);
        }
        case SHAPE_GYROID: {
            return gyroidSDF(center, 0.5);
        }
        default: {
            return sphereSDF(center);
        }
    }
}

fn viewMatrix(camera_position: vec3f, center: vec3f, up: vec3f) -> mat4x4<f32> {
    let f: vec3f = normalize(center - camera_position);
    let s: vec3f = normalize(cross(f, up));
    let u: vec3f = cross(s, f);
    return mat4x4<f32>(
        vec4f(s, 0.0),
        vec4f(u, 0.0),
        vec4f(-f, 0.0),
        vec4f(0.0, 0.0, 0.0, 1.0)
    );
}

// Primitives SDF
fn sphereSDF(p: vec3f) -> f32 {
    var r = 1.0;
    return length(p) - r;
}

fn roundBoxSDF(p: vec3f, b: vec3f, r: f32) -> f32 {
  let q = abs(p) - b;
  return length(max(q, vec3f(0.))) + min(max(q.x,max(q.y, q.z)), 0.) - r;
}

fn torusSDF(p: vec3f, R: f32, r: f32) -> f32 {
  let q = vec2f(length(p.xz) - R, p.y);
  return length(q) - r;
}

fn BoxFrameSDF(p: vec3f, b: vec3f, e: f32, r: f32) -> f32 {
  let q = abs(p) - b;
  let w = abs(q + e) - e;
  return min(min(
      length(max(vec3f(q.x, w.y, w.z), vec3f(0.))) + min(max(q.x, max(w.y, w.z)), 0.) - r,
      length(max(vec3f(w.x, q.y, w.z), vec3f(0.))) + min(max(w.x, max(q.y, w.z)), 0.) - r),
      length(max(vec3f(w.x, w.y, q.z), vec3f(0.))) + min(max(w.x, max(w.y, q.z)), 0.) - r);
}

fn gyroidSDF(p: vec3f, h: f32) -> f32 {
    let box_size = vec3f(1.0);
    
    let scale = 6.5;
    
    let scaled_p = (p + vec3f(2.0)) * scale;
    let gyroid = 0.5 * (abs(dot(sin(scaled_p * 1.8), cos(scaled_p.zxy))) - h) / scale;
    
    let box_dist = roundBoxSDF(p, box_size, 0.0);
    
    return max(box_dist, gyroid);
}

// CSG Operations
fn intersectSDF(a: f32, b: f32, k: f32) -> f32 {
    let h: f32 = clamp(0.5 - 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) + k * h * (1.0 - h);
}

fn unionSDF(a: f32, b: f32, k: f32) -> f32 {
    let h: f32 = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

fn subtractSDF(a: f32, b: f32, k: f32) -> f32 {
    let h: f32 = clamp(0.5 - 0.5 * (b + a) / k, 0.0, 1.0);
    return mix(b, -a, h) + k * h * (1.0 - h);
}
