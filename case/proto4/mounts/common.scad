module sensor_plate() {
    thick=4;
    translate([0, 0, -thick])
    color("#0099FF")
    difference() {
        ccube([57, 57, thick]);

        cdist=56;
            translate([cdist/2-1, cdist/2-1, -1])
                cylinder(r=7, h=7);
            translate([-cdist/2+1,cdist/2-1, -1])
                cylinder(r=7, h=7);
            translate([cdist/2-1, -cdist/2+1, -1])
                cylinder(r=7, h=7);
            translate([-cdist/2+1, -cdist/2+1, -1])
                cylinder(r=7, h=7);


            rotate(30) {
            offset=38;
            depth=4;
            translate([offset/2, offset/2, depth])
            rotate([180, 0, 0])
                screwhole(2.5, 5, 8, 2);
            translate([-offset/2, offset/2, depth])
            rotate([180, 0, 0])
                screwhole(2.5, 5, 8, 2);
            translate([-offset/2, -offset/2, depth])
            rotate([180, 0, 0])
                screwhole(2.5, 5, 8, 2);
            translate([offset/2, -offset/2, depth])
            rotate([180, 0, 0])
                screwhole(2.5, 5, 8, 2);
        }
    }
}

module mount_sensor() {
    rotate(30) {
        offset=38;
        translate([offset/2, offset/2, -0.01])
        rotate([180, 0, 0])
            insert(2.5, 4, 3);
        translate([-offset/2, offset/2, -0.01])
        rotate([180, 0, 0])
            insert(2.5, 4, 3);
        translate([-offset/2, -offset/2, -0.01])
        rotate([180, 0, 0])
            insert(2.5, 4, 3);
        translate([offset/2, -offset/2, -0.01])
        rotate([180, 0, 0])
            insert(2.5, 4, 3);
    }
}

module cam4_mount(hole=40, hfn=4, mft_pin=false, sensor_mount=true) {
    size=62;
    screw_spacing=52;
    difference() {
        union() {
            difference() {
                linear_extrude(3) {
                    rsquare2([size, size], 5);
                }
                translate([screw_spacing/2, screw_spacing/2, 0])
                    screwhole(2.5, 5, 8, 2);
                translate([-screw_spacing/2, screw_spacing/2, 0])
                    screwhole(2.5, 5, 8, 2);
                translate([screw_spacing/2, -screw_spacing/2, 0])
                    screwhole(2.5, 5, 8, 2);
                translate([-screw_spacing/2, -screw_spacing/2, 0])
                    screwhole(2.5, 5, 8, 2);

                children();

                translate([0, 0, -1])
                rotate([0, 0, 45])
                    cylinder(r=hole/2, h=10, $fn=hfn);

                if(mft_pin){
                translate([48/2, 0, -4])
                    cylinder(r=1.5/2, h=10, $fn=40);
                }

            }
            children();
        }
        if(sensor_mount) {
            mount_sensor();
        }
    }

    if($preview) {
        hole = size - 4;
        color("red")
        translate([0, 0 ,-5])
        union() {
            shell([hole+4, hole+4, 5], 1, 2);
            translate([hole/2-1, hole/2-1, 0])
                cylinder(r=7, h=7);
            translate([-hole/2+1, hole/2-1, 0])
                cylinder(r=7, h=7);
            translate([hole/2-1, -hole/2+1, 0])
                cylinder(r=7, h=7);
            translate([-hole/2+1, -hole/2+1, 0])
                cylinder(r=7, h=7);
        }
    }
}
