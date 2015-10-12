color( "silver", 1 ) {

cube([1000, 125, 5000]);
translate([18000,0,0])
  cube([1000, 125, 5000]);
 
 translate([1000, 0, 0])
    rotate([0, 0, 45])
        cube([2000, 125, 5000]);
 
 translate([18000, 0, 0])
    rotate([0, 0,  135])
        cube([2000, 125, 5000]);
        
translate([2414, 1414, 0])
    cube([14160, 125, 5000]);
}

color ( "darkslategray", .5)
translate ([0, -1500, 0])
   cube([19000,  250, 5000]);

color ("green", 1) {
    translate([2500, 0, 1000])
        cube([4500, 100, 3500]);
    translate([7000, 0, 1000])
        cube([4500, 100, 3500]);
    translate([11000, 0, 1000])
        cube([4500, 100, 3500]);
}

// The rack-mount screws
translate([500, -1000, 1500])
rotate([90, 0, 0])
cylinder(3000, 100, 100, true);

translate([500, -1000, 3500])
rotate([90, 0, 0])
cylinder(3000, 100, 100, true);

translate([18500, -1000, 1500])
rotate([90, 0, 0])
cylinder(3000, 100, 100, true);

translate([18500, -1000, 3500])
rotate([90, 0, 0])
cylinder(3000, 100, 100, true);

// The PCB standoffs
color("blue") {
translate([4000, 800, 1500])
rotate([90,0,0])
cylinder(1000, 100, 100, true);

translate([4000, 800, 3500])
rotate([90,0,0])
cylinder(1000, 100, 100, true);

translate([8000, 800, 1500])
rotate([90,0,0])
cylinder(1000, 100, 100, true);

translate([8000, 800, 3500])
rotate([90,0,0])
cylinder(1000, 100, 100, true);


translate([13000, 800, 1500])
rotate([90,0,0])
cylinder(1000, 100, 100, true);

translate([13000, 800, 3500])
rotate([90,0,0])
cylinder(1000, 100, 100, true);
}
