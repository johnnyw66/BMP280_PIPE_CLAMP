// ====================================================================
// BMP280 UK Pipe Clamp
// Cleaned: Top cylinder arch/bridge cut flush to open slide path
// ====================================================================

$fn = 120;

// --- Pipe & Clip Geometry ---
pipe_od          = 15.2;   // 15mm metric nominal
pipe_r           = pipe_od / 2;
wall_th          = 2.8;    // Spring wall thickness
clip_angle       = 230;    // Wrap angle (>180 gives snap retention)

// --- PCB Pocket & Slide-In Rails ---
pcb_w            = 15.3;   // Width clearance for 15.0mm board
pcb_l            = 15.3;   // Length
track_depth      = 2.3;    // Thickness allowance for PCB + thermal pad
rail_lip         = 1.2;    // Overlap on left/right edges to trap PCB

// --- Thermal Pad Window ---
sensor_window_w  = 10.0;   // Window directly exposing pipe surface
sensor_window_l  = 10.0;

// --- Cable Slot (Open from the top) ---
cable_ch_w       = 3.4;    // Cleared width (cable drops in freely)
cable_run_len    = 12.0;   // Length of strain relief lead

// Overall length
total_len        = pcb_l + cable_run_len + 3.0; // ~30.3mm
overlap          = 1.0;    // Eliminates zero-thickness CSG artifacts

// --- Zip-Tie Strain Relief ---
tie_w            = 2.8;   // Slot width along Z (fits standard 2.5mm miniature zip-tie)
tie_th           = 1.8;   // Slot thickness/depth in Y
tie_z_pos        = 5.0;   // Height from bottom edge

module prewired_pipe_clamp() {
    difference() {
        // --- 1. Outer Solid ---
        union() {
            // Main pipe-gripping cylinder
            cylinder(r = pipe_r + wall_th, h = total_len);
            
            // Sensor and cable platform
            translate([- (pcb_w + 4.0)/2, pipe_r - 0.2, 0])
                cube([pcb_w + 4.0, wall_th + 3.8, total_len]);
        }
        
        // --- 2. Pipe Bore (Cuts past both ends) ---
        translate([0, 0, -overlap])
            cylinder(r = pipe_r, h = total_len + 2 * overlap);
        
        // --- 3. C-Clip Snap Mouth Cutout (Cuts past both ends) ---
        translate([0, 0, -overlap])
            rotate([0, 0, - (360 - clip_angle) / 2 - 90])
                wedge_cut(r = pipe_r + wall_th + 5, h = total_len + 2 * overlap, a = 360 - clip_angle);

        // --- 4. PCB Slide-In Pocket (Runs cleanly out top end) ---
        translate([- pcb_w / 2, pipe_r + 0.8, cable_run_len])
            cube([pcb_w, track_depth, pcb_l + 10]);
            
        // Top opening between side rails
        translate([- (pcb_w - 2 * rail_lip) / 2, pipe_r + 0.8 + track_depth - 0.1, cable_run_len])
            cube([pcb_w - 2 * rail_lip, 10, pcb_l + 10]);

        // --- 5. Direct Thermal Window ---
        translate([- sensor_window_w / 2, pipe_r - 2, cable_run_len + (pcb_l - sensor_window_l)/2])
            cube([sensor_window_w, 4, sensor_window_l]);

        // --- 5b. TOP ARCH CLEARANCE CUT (Your exact fix made parametric) ---
        // Extends the thermal window opening straight out the top end (Z)
        translate([- sensor_window_w / 2, pipe_r - 2, cable_run_len + (pcb_l - sensor_window_l)/2])
            cube([sensor_window_w, wall_th + 10, total_len]);

        // --- 6. Open Cable Drop-In Slot (Cuts through Z = 0) ---
        translate([- cable_ch_w / 2, pipe_r + 0.8, -overlap])
            cube([cable_ch_w, 10, cable_run_len + overlap + 0.1]);

        // --- 7. Under-Slung Zip-Tie Tunnel ---
        translate([- (pcb_w + 6)/2, pipe_r + 2.2, tie_z_pos])
            cube([pcb_w + 6, tie_th, tie_w]);
    
        // --- 8. Mouth Chamfers ---
        for (side = [-1, 1]) {
            rotate([0, 0, side * (clip_angle / 2 - 90)])
                translate([0, pipe_r + wall_th / 2, total_len / 2])
                    rotate([0, 0, 45])
                        cube([1.8, 1.8, total_len + 2 * overlap], center = true);
        }
    }
}

// Wedge helper with clean outer radius bounds
module wedge_cut(r, h, a) {
    linear_extrude(height = h) {
        polygon(points = [
            [0, 0],
            [r * cos(0), r * sin(0)],
            [r * cos(a/2), r * sin(a/2)],
            [r * cos(a), r * sin(a)]
        ]);
    }
}

prewired_pipe_clamp();