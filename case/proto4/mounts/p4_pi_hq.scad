include<../../lib/components.scad>;
include<common.scad>;


module mount_picam(hole=36.4, height=7) {
    // z=0 of this module is the flange

    inset=4;
    screw_r=1.7/2;
    rectangle_length=48;

    union() {


        difference(){
            union() {
                cylinder(r=45/2, h=height, $fn=180);
                translate([0, 0, 3])
                    fillet(45/2, 8, $fn=90);
            }

            translate([0, 0, -1])
            cylinder(r=hole/2, h=height+2, $fn=180);

            translate([-10.5/2, 16.6, -1])
                cube([10.5, 5, height+2]);
        }
    }
}

module fillet(r, size, $fn) {
    rotate_extrude(convexity = 10, $fn=$fn)
    translate([r, 0, 0])
        difference() {
            square(size);
            translate([size, size])
            circle(size, $fn=$fn);
        }
}

difference() {
    cam4_mount(sensor_mount=false, hole=30) {
            translate([0, 0, 0])
                mount_picam(height=11.4);
    }
    
    // Screw holes for the pi module
    corners(30, 30, center=true)
        translate([0, 0, -0.01])
        rotate([180, 0, 0])
            insert(2.5, 4, 3);
    
    // Hole for the CS mount
    translate([0, 0, -0.01])
        cylinder(r=36/2+0.2, h=10, $fn=90);
    translate([-10.5/2, 16.6, -1])
        cube([10.5, 5, 10]);


}
//picam_cs();