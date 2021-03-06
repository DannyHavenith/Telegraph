ring_outer_r = 43;
switch_height = 13;
ring_inner_r = ring_outer_r - switch_height;
dimple_depth = 1.8;
ring_height = ring_outer_r - ring_inner_r; 
dimple_diameter = 8;
ring_thickness = 12;
feet_height = 7;
play = .2; // space between parts that should fit.
feet_inset = 1+play;
trench_depth = 3;
trench_width = 2;
axis_d = 10;
d = 0.01;
function up(v,w) = [v.x*w.x, v.y*w.y, v.z*w.z];


// choose what to generate
//rings();
//rotate([90,0,0]) 
    lever();
//switch_ring();
//everything();
//switch_support_ring();

module switch()
{
    cube_dims = [6,7.5,3.5] + [.5, .5, .5];
    button_diameter = 3.7;
    
    // switch housing
    translate(up(cube_dims,[ -.5, -.5, 0]) - [0,0,1+d]) cube(cube_dims + [0,0,d+1]);
    
    // button pole
    cylinder( d = button_diameter, h = switch_height+ d, $fn = 40);
}

module ring( inner_r, outer_r, h, center = false)
{
    translate([0,0, center?0:h/2])
    difference() 
    {
        cylinder(r = outer_r, h = h, center=true);
        cylinder( r = inner_r, h = h + 2*d, center=true);
    }
}

module foot(expand = false)
{
    foot_extent = 10;
    exp_dims = (expand?[play, play, d]:[0,0,0]);
    feet_dims = [ feet_height, ring_thickness + feet_inset + foot_extent, ring_height + foot_extent] + exp_dims;
    tab_dims = [feet_height, 1, trench_width - play];
    translate([-d, ring_inner_r - feet_inset, -ring_thickness/2] - exp_dims) 
        difference()
        {
            union()
            {
                cube(feet_dims);
                
                rib_depth = trench_depth/5;
                for (offset = [-3, 3])
                    translate([0,-rib_depth, ring_thickness/2 + play -trench_width/2 + offset]) cube([feet_height, trench_depth, trench_width - 2 * play]);
            }
            screw_offset = [-d, ring_thickness + feet_inset + foot_extent/2, ring_height + foot_extent/2];
            // the dimensions below are better suited, but I need the ones above for compatibility 
            // with the box that this is built into
            //screw_offset = [-d, ring_thickness + feet_inset + foot_extent*.4, ring_height + foot_extent * .4];
            translate(screw_offset) 
                rotate([0,90,0]) screw( $fn= 50);
        }
    
}

module feet(expand = false)
{
    foot( expand);
    mirror([0,1,0]) foot(expand);        
}

module switch_ring()
{
    inner_guide_depth = .6;
    guide_depth = .4;
    guide_width = 1.2;
    
    switch_count = 5;
    
    // angular distance between switch positions
    angle = 180/switch_count;
    
    difference()
    {
        union()
        {
            ring( ring_inner_r, ring_outer_r, ring_thickness, center=true, $fn = 1000);
            for (offset = [-3, 3])
            translate([0,0,offset])
                ring( inner_r = ring_inner_r - inner_guide_depth , outer_r = ring_inner_r + +d, h = trench_width-2*play, center=true,$fn = 1000);
        }
        //ring(inner_r = ring_outer_r - guide_depth, outer_r = ring_outer_r + 1, h = guide_width, center = true, $fn = 500);
        
        for ( i = [0:switch_count-1])
        {
            rotate([0,0, angle/2 + i * angle])
            {
                #translate([0,ring_inner_r - d, 0]) rotate([-90,0,0]) 
                    switch();
                translate([0,ring_outer_r - dimple_depth - d, 0]) rotate([-90,0,0]) 
                    cylinder( d1 = d, d2 = dimple_diameter, h = dimple_depth + d , $fn = 40);
            }
        }
        
        cutter_dims = [ring_outer_r, 2*ring_outer_r, ring_thickness] + [d, 2*d, 2*d];
        translate([cutter_dims.x/2, 0, 0]) cube(cutter_dims, center=true);
    }
    
    feet();
}

module screw()
{
    head_d = 9.5;
    head_depth = 4;
    screw_d = 5;
    screw_length = 24;
    
    cylinder(d = head_d, h = head_depth);
    cylinder(d= screw_d, h = screw_length);
}

module switch_support_ring()
{
    difference()
    {
        cylinder(r = ring_inner_r - play, h = ring_thickness, center=true, $fn = 500);
        feet( expand = true);
        cutter_dims = [ring_inner_r, 2*ring_inner_r, ring_thickness] + [d, 2*d, 2*d];
        translate([feet_height + cutter_dims.x/2 - 2*d, 0, 0]) cube( cutter_dims, center=true);
        for (offset = [-3, 3])
            translate([0,0,offset])
                ring( inner_r = ring_inner_r - trench_depth , outer_r = ring_inner_r + 10, h = trench_width, center=true,$fn = 100);
        cylinder( d = axis_d, h = ring_thickness + 2 * d, center=true, $fn=1000);
        
        slot_dims = [feet_height, axis_d-play/2, ring_thickness];
        translate(up(slot_dims, [.5, 0, 0])) cube( slot_dims + [d,0,2*d], center=true);
    }
}

// a flat cube with rounded (cylindrical) corners.
module flatroundedcube( dimensions, r)
{
    rs = [r,r,0];
    inner = dimensions - 2 * rs;
    translate( -inner/2)
        hull()
            for ( x = [0:1]) for ( y = [0:1])
                translate(up( inner, [x,y,0])) cylinder( h = dimensions[2], r = r, $fn = 20);
}

lever_brace_thickness = 6; // thickness of the "metal" brace of the lever
module lever()
{
    lever_d2 = 15; // the diameter of the actual lever, top
    lever_d1 = 12; // bottom
    lever_length = 60;
    lever_stem_length = lever_length - lever_d2/2;
    hole_size = 17; // size of the gap between the two "pointers" of the lever
    taper_start = 10.5;
    
    // The pin that clicks in to the cavities on the switch ring is floating 
    // in the lever. There's a cavity behind the pin and the pin is on a spring that
    // has been cut into the top of the brace.
    cut_width = 1;
    cut_depth = 1.6;
    cavity = 2;
    
    // squares used to cut a gap in the side of the lever brace.
    module cutter()
    {
        cutter_dims = [100, lever_brace_thickness + 2*d, 100];
        translate([0, inner_dims.y/2 - d, -hole_size/2]) rotate([0, -45, 0]) cube(cutter_dims);
    }
    
    inner_dims = [ ring_outer_r + axis_d/2 + 2*play, ring_thickness + 4 * play, lever_d2];
    outer_dims = inner_dims + [lever_brace_thickness, 2* lever_brace_thickness , -2*d];
    offset_to_upper_brace = -inner_dims.x/2 + lever_brace_thickness/2;

    difference()
    {
        flatroundedcube(outer_dims, 3);
        translate([lever_brace_thickness/2 + d, 0, 0]) cube(inner_dims, center = true);
        
        // cut out one side to leave "pointer" shapes.
        cutter();
        rotate([0,180,0]) cutter();
        
        // cut off the far end, near the axis
        translate([outer_dims.x - taper_start, 0, 0]) cube(outer_dims + [d,d,d], center = true);
        
        spring_extent = inner_dims.x/2;
        // slits to separate the spring from the lever
        cutter_dims = [spring_extent + cut_depth + cavity + d, inner_dims.y + cut_depth + d, cut_width];
        for (i = [-1,1])
            translate([ offset_to_upper_brace + cutter_dims.x/2 - cut_depth -d, -cut_depth/2 -d, i * dimple_diameter/2])
                cube( cutter_dims, center = true);
                
        // cavity behind the long tongue of the spring
        long_cavity_dims = [cutter_dims.x + cavity, cavity, dimple_diameter];
        translate([ offset_to_upper_brace + long_cavity_dims.x/2 - cut_depth - cavity -d, -inner_dims.y/2 - cut_depth - long_cavity_dims.y/2,0])
            cube(long_cavity_dims, center=true);
        
        // cavity behind the spring
        short_cavity_dims = [cavity, inner_dims.y + 2 * cut_depth + 2 * d, dimple_diameter+cut_width];
        translate([-inner_dims.x/2 + lever_brace_thickness/2 - (cut_depth+short_cavity_dims.x/2),0,0]) cube(short_cavity_dims, center=true);

        // disconnect the spring from the lever on one side
        disconnect_dims = [ 2 * cut_depth, cut_width, dimple_diameter + 2*d];
        translate([offset_to_upper_brace - disconnect_dims.x/2 + 2*d, inner_dims.y/2 - disconnect_dims.y/2, 0])
            cube(disconnect_dims, center=true);
        vert_dims = [2*cut_depth, cut_width/2, dimple_diameter*.6];
        
        // cut the lever in half to check the cavities.
        //translate([0,200,0]) cube([400,400,400], center=true);

    }
    
    //translate([offset_to_upper_brace, 0, 8]) cylinder( d=1, center=true, $fn=8);
    for ( i = [-1, 1]) translate([outer_dims.x/2 - axis_d/2, i * (inner_dims.y/2 + lever_brace_thickness/2),0])
        hull()
        {
            rotate([90,0,0]) cylinder(d = axis_d/2 + feet_height - play, h = lever_brace_thickness, center=true, $fn = 100);
            translate([-taper_start+axis_d/2, 0, 0]) cube([d, lever_brace_thickness, outer_dims.z], center=true);
        }
    
    // axis
    translate( [outer_dims.x/2 - axis_d/2, 0,0]) rotate([90,0,0]) cylinder( d = axis_d, h = inner_dims.y, center=true, $fn=100);
    
    // actual lever
    translate( [-outer_dims.x/2 + d, 0, 0]) rotate([0,-90,0]) cylinder(d1 = lever_d1, d2 = lever_d2, h = lever_stem_length, $fn = 100);
    
    // bump/pin
    translate([ -inner_dims.x/2 + d + lever_brace_thickness/2, 0, 0]) 
        rotate([0,90,0]) 
            cylinder( d1 = dimple_diameter, d2 = d, h = dimple_depth + 2*play, $fn = 100);
}

module rings()
{
    color( "cyan") switch_ring();
    color( "blue") switch_support_ring();
}

module everything()
{
    difference()
    {
        union()
        {
            translate([-(ring_outer_r + axis_d/2 + play + lever_brace_thickness - axis_d)/2, 0, 0]) 
                rotate([90,0,0]) lever();
            rings();
        }
        
        // Cut everything in half to see whether the inner parts are placed correctly
        translate([-200, 0, -100]) cube([400,200,200]);
    }
}
