// ====================================================================
// Reusable Retention Clip for I2C Strain-Relief Tunnel
// Prints flat on the build plate (XY plane) for maximum layer strength
// ====================================================================

$fn = 60;

// Matching clamp dimensions
pcb_w         = 15.3;
spine_w       = pcb_w + 4.0;   // 19.3 mm (width of the clamp platform)
tunnel_th     = 1.8;          // Tunnel depth (Y)
tunnel_w      = 2.8;          // Tunnel height (Z)

// Clip-specific tolerances & sizing
fit_gap       = 0.25;         // Clearance for easy slide-in
prong_th      = tunnel_th - fit_gap * 2; // ~1.3 mm
prong_w       = tunnel_w  - fit_gap * 2; // ~2.3 mm
barb_len      = 1.0;          // How far barbs flare outward to lock
clip_span     = spine_w + 2.0;// Internal span between legs

module strain_relief_clip() {
    // 1. Center Cross-Bar (Sits over the cable)
    translate([-clip_span/2, -tunnel_th/2, 0])
        cube([clip_span, tunnel_th + 1.2, prong_w]);
    
    // Cable pressure saddle (pushes down on the wire)
    translate([-2.0, -tunnel_th/2 - 0.8, 0])
        cube([4.0, 0.8, prong_w]);

    // 2. Twin Locking Prongs
    for (side = [-1, 1]) {
        translate([side * (clip_span/2 - prong_th/2), 0, 0]) {
            // Main shaft of prong
            translate([-prong_th/2, 0, 0])
                cube([prong_th, spine_w/2 + 2.0, prong_w]);

            // Snap Barb on the end
            translate([side * (prong_th/2), spine_w/2 + 1.0, 0])
                linear_extrude(height = prong_w)
                    polygon([
                        [0, 0],
                        [side * barb_len, 0],
                        [0, 1.8]
                    ]);
        }
    }
}

strain_relief_clip();