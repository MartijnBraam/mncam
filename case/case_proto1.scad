// Show camera mount
show_front=true;

// Show display
show_left=true;

// Show I/O panel
show_right=true;

// Show rear panel
show_rear=true;

// Show mounting plate
show_bottom=true;

// Show top plate
show_top=true;

// Show modules
show_modules=true;

// Camera outder dimensions
cam_w=90;
cam_l=140;

include<components.scad>;


module cpu_board() {
    color("#090")
    translate([6,0,-1.6])
    cube([68, 120, 1.6]);
}

module bottom() {
    thick=7;
    spacer=5;
    
    if ($preview && show_modules && false) {
        translate([0,0,thick+1.6+spacer])
            cpu_board();
    }
    
    translate([10, 30, thick+1.6+spacer])
        raspberry_pi();
    
    difference() {
        translate([0,0,0])
            cube([cam_w, cam_l, thick]);
        
        // Prevent bottom plate from sticking through the display chamfer
        translate([cam_w, 10.3, 0])
        rotate([45, 0, 90])
            cube([120.7, 20, 20]);
        
        // Bottom mounting holes
        translate([cam_w/2,cam_l/3,-0.01])
        rotate([180, 0, 0])
            insert(0, 7.15, 6);
        
        translate([cam_w/2,cam_l/2,-0.01])
        rotate([180, 0, 0])
            insert(0, 7.15, 6);

        
        translate([cam_w/2,cam_l/3*2,-0.01])
        rotate([180, 0, 0])
            insert(0, 7.15, 6);

    }
}

module display() {
    thick=5;
    dw=120.7;
    dh=77.2;

    if ($preview && show_modules) {
        translate([7, 10, 0.98])
            rotate([0,0,0])
            waveshare5inch();
    }

    difference() {
        cube([cam_w, cam_l, thick]);
        
        translate([cam_w/2-2, cam_l/2, -0.01])
        linear_extrude(1, scale=[0.85, 0.90])
            square([dh, dw], center=true);
        
        translate([thick+2, 10, 0.9])
            cube([dh+30, dw+0.3, 10]);
    }
    
    translate([5, 10, 5])
        cube([2, dw, 5]);
}

module side_io() {
    thick=5;
    dw=10;
    dh=10;
    difference() {
        cube([cam_w, cam_l, thick]);
        
        translate([cam_w/2-20, cam_l/2, -0.01])
        linear_extrude(1, scale=[0.85, 0.90])
            square([dh, dw], center=true);
        
        translate([thick+2, 10, 0.9])
            cube([dh+30, dw+0.3, 10]);
    }
}

module rear() {
    thick=5;
    difference() {
        cube([cam_w, cam_w, thick]);
    }
}

module top() {
    thick=7;
    difference() {
        translate([0,0,0])
            cube([cam_w, cam_l, thick]);
                
        // LCD panel cutout
        translate([cam_w-11,8,5.7])
            cube([10, 123, 10]);
        
        // Top mounting holes
        translate([cam_w/2,cam_l/3,-0.01])
        rotate([180, 0, 0])
            insert(0, 7.15, 6);
        
        translate([cam_w/2,cam_l/2,-0.01])
        rotate([180, 0, 0])
            insert(0, 7.15, 6);

        translate([cam_w/2,cam_l/3*2,-0.01])
        rotate([180, 0, 0])
            insert(0, 7.15, 6);
    }
}

module case() {
    // Bottom
    if (show_bottom)
        bottom();
    
    // Front
    if (show_front)
    rotate([90, 0, 0])
        mount_cs();
    
    // Side
    if (show_left)
    translate([cam_w, 0, 0])
    rotate([0,-90,0])
        display();
    
    // Other side
    if (show_right)
    translate([0,cam_l,0])
    rotate([0,-90,180])
        side_io();
    
    // Rear
    if (show_rear)
    translate([0,cam_l,0])
    rotate([90,0,0])
        rear();
    
    // Top
    if (show_top)
    translate([0, cam_l, cam_w])
    rotate([180 ,0 ,0])
        top();
}

module case_chamfered() {
    c=8;
    difference() {
        case();
        
        translate([0, -5, -(c/2)*sqrt(2)])
        rotate([45, 0, 90])
            cube([cam_l+10, c, c]);
        
        translate([cam_w, -5, -(c/2)*sqrt(2)])
        rotate([45, 0, 90])
            cube([cam_l+10, c, c]);

        translate([0, -5, -(c/2)*sqrt(2)+cam_w])
        rotate([45, 0, 90])
            cube([cam_l+10, c, c]);
        
        translate([cam_w, -5, -(c/2)*sqrt(2)+cam_w])
        rotate([45, 0, 90])
            cube([cam_l+10, c, c]);

        translate([-(c/2)*sqrt(2), 0, cam_w+5])
        rotate([45, 90, 0])
            cube([cam_w+10, c, c]);
            
        translate([-(c/2)*sqrt(2), cam_l, cam_w+5])
        rotate([45, 90, 0])
            cube([cam_w+10, c, c]);

        translate([-(c/2)*sqrt(2)+cam_w, cam_l, cam_w+5])
        rotate([45, 90, 0])
            cube([cam_w+10, c, c]);

        translate([-(c/2)*sqrt(2)+cam_w, 0, cam_w+5])
        rotate([45, 90, 0])
            cube([cam_w+10, c, c]);

        translate([0,0,-(c/2)*sqrt(2)])
        rotate([45, 0, 0])
            cube([cam_w+10, c, c]);

        translate([0,0,-(c/2)*sqrt(2)+cam_w])
        rotate([45, 0, 0])
            cube([cam_w+10, c, c]);
            
        translate([0,cam_l,-(c/2)*sqrt(2)])
        rotate([45, 0, 0])
            cube([cam_w+10, c, c]);

        translate([0,cam_l,-(c/2)*sqrt(2)+cam_w])
        rotate([45, 0, 0])
            cube([cam_w+10, c, c]);
    }
}

module case_bottom() {
    difference() {
        case_chamfered();
        
        // Remove top panel
        translate([0, 8, cam_w-7.01])
            cube([cam_w+10, cam_l+10, 10]);
        
        // Remove right side
        translate([-4.99, 8, 7])
            cube([10, cam_l+10, cam_w+10]);
        
        // Remove rear panel
        translate([-10-5, cam_l-9, 7])
            cube([cam_w+10, 10, cam_w+10]);
        
        // Front screw holes
        translate([10, 6, cam_w-3])
        rotate([90, 0, 0])
            screwhole(2.5, 4);
        translate([cam_w-10, 6, cam_w-3])
        rotate([90, 0, 0])
            screwhole(2.5, 4);
            
        // Bottom screw holes
        translate([2.5, 14, 5])
        rotate([180, 0, 0])
            screwhole(2.5, 4);
        translate([2.5, cam_l/2, 5])
        rotate([180, 0, 0])
            screwhole(2.5, 4);
        translate([2.5, cam_l-14, 5])
        rotate([180, 0, 0])
            screwhole(2.5, 4);

        // Display side screw holes
        translate([cam_w-3, cam_l-5, 14])
        rotate([0, 90, 0])
            screwhole(2.5, 4);
        translate([cam_w-3, cam_l-5, cam_w-14])
        rotate([0, 90, 0])
            screwhole(2.5, 4);

    }
}

case_bottom();

/*
if (show_modules) {
color("#333")
translate([25, 75+40, 100])
rotate([90, 0, 0])
cylinder(r=20, h=75, $fn=90);
}
//display();
*/