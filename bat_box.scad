// Bat Box
// A small roost box that screws onto a post or tree.
//
//  - Inside chamber is 100 wide x 48 deep x 150 tall (mm)
//  - The front wall stops short of the bottom, leaving an entry slot across
//    the full width; the bottom is open too, so droppings fall out
//  - The back plate runs below the box as a landing pad
//  - Shallow horizontal grooves on the inside of the back, the front and the
//    landing pad give the bats something to grip
//  - Four tabs at the corners of the back plate have countersunk holes for
//    screws into a post or tree; they angle back so the box hugs a
//    round trunk
//  - The roof overhangs the front and sides to keep rain out of the entry
//  - Rounded corners and edges all round, and a bat engraved on the front
//
// Printing: print upside down, roof on the bed (part = "print"). Every
// overhang is 45 degrees or less, so no supports are needed.
// Total print height is about 194 mm.

/* [Part to show / export] */
part = "assembled"; // ["assembled", "print", "section"]

/* [Color] */
print_color = "#EFE6D2"; // beige / off-white

/* [Inside of the box] */
inner_w = 100; // width, side to side
inner_d = 48;  // depth, back to front
inner_h = 150; // height, open bottom to underside of the roof

/* [Walls] */
wall   = 3.5; // side walls and front
back_t = 5;   // back plate and mounting tabs
roof_t = 4;
open_bottom = true; // false adds a floor (the front entry slot stays open)

/* [Entry and landing] */
entry_h   = 30; // height of the open slot at the bottom of the front
landing_h = 40; // how far the back plate runs below the box
overhang  = 10; // how far the roof sticks out past the front
side_oh   = 3;  // how far the roof sticks out past each side

/* [Rounding] */
corner_r = 6;   // vertical front corners of the box
roof_r   = 8;   // front corners of the roof
edge_r   = 1.5; // fillet on exposed edges
roof_edge_r = 2; // fillet on the top of the roof (differs from edge_r so it meets the tabs cleanly)
slot_r   = 6;   // corners of the entry slot
tab_r    = 5;   // outer corners of the tabs

/* [Bat engraving] */
bat_w     = 75;  // wingspan of the engraved bat
bat_depth = 1;   // engraving depth
bat_z     = 0.55; // height of the bat on the front, 0 = slot top, 1 = roof

/* [Grip grooves] */
groove_depth = 1.2;
groove_pitch = 5;

/* [Mounting tabs] */
tab_out = 20;  // how far each tab sticks out past the side of the back
tab_h   = 20;  // height of a tab where it sits at a corner
tab_angle = 15; // how far the tabs bend back to wrap a tree; 0 = flat
screw_d = 4.5; // clearance hole for a #8 / 4 mm wood screw
head_d  = 9;   // countersink diameter at the surface

$fn = 48;

eps = 0.01;
outer_w = inner_w + 2 * wall;
top_z   = inner_h + roof_t;  // top of the roof and back plate
bot_z   = -landing_h;        // bottom of the landing pad
floor_t = open_bottom ? 0 : wall;

// --- helpers ---------------------------------------------------------------

// Rectangle with the two front (+Y) corners rounded and the back ones square.
module front_round_rect(x0, y0, x1, y1, r) {
    hull() {
        translate([x0, y0]) square([x1 - x0, eps]);
        for (x = [x0 + r, x1 - r]) translate([x, y1 - r]) circle(r);
    }
}

// Extrudes a convex 2D child to height h with filleted top and/or bottom edges.
module rounded_slab(h, r_top = 0, r_bot = 0, steps = 6) {
    hull() {
        translate([0, 0, r_bot]) linear_extrude(max(h - r_top - r_bot, eps)) children();
        for (i = [0 : steps]) {
            a = 90 * i / steps;
            if (r_top > 0)
                translate([0, 0, h - r_top + r_top * sin(a) - eps])
                    linear_extrude(eps) offset(delta = -r_top * (1 - cos(a))) children();
            if (r_bot > 0)
                translate([0, 0, r_bot - r_bot * sin(a)])
                    linear_extrude(eps) offset(delta = -r_bot * (1 - cos(a))) children();
        }
    }
}

// Extrudes a convex outline in the XZ plane through the back plate,
// rounding the front (y = 0) edges and keeping the back face flat.
module plate_piece() {
    rotate([90, 0, 0]) rounded_slab(back_t, r_bot = edge_r) children();
}

function bez(p0, c, p1, n = 8) = [for (i = [0 : n]) let (t = i / n)
    (1 - t) * (1 - t) * p0 + 2 * (1 - t) * t * c + t * t * p1];

// --- bat silhouette --------------------------------------------------------

// Right half, from the top of the head round to the tail; about 104 x 27 units.
bat_half = concat(
    [[0, 8], [2.5, 15], [4.5, 8], [5.5, 5]],
    bez([6, 4], [14, 14], [26, 17]),        // shoulder up to the wrist
    bez([26, 17], [40, 20], [52, 14]),      // wrist out to the wing tip
    bez([52, 14], [44, 10], [42, 2]),       // scalloped trailing edge
    bez([42, 2], [35, 5], [30, -3]),
    bez([30, -3], [23, 3], [17, -4]),
    bez([17, -4], [11, 2], [6, -3]),
    [[5, -5], [3, -10], [0, -12]]
);

module bat_2d() {
    pts = concat(bat_half,
                 [for (i = [len(bat_half) - 2 : -1 : 1]) [-bat_half[i][0], bat_half[i][1]]]);
    scale(bat_w / 104) polygon(pts);
}

module bat_engraving() {
    z = entry_h + slot_r + (inner_h - entry_h - slot_r) * bat_z;
    translate([inner_w / 2, inner_d + wall + eps, z]) rotate([90, 0, 0])
        linear_extrude(bat_depth + eps) bat_2d();
}

// --- back plate and tabs ---------------------------------------------------

// One tab in (outward, up) coordinates, reaching 10 mm into the plate so its
// rounded edges are buried. The inner edge rises at 45 degrees so the tabs
// print without support when upside down.
module tab_2d() {
    offset(r = tab_r) offset(delta = -tab_r)
        polygon([[-10, 0], [tab_out, 0], [tab_out, tab_h],
                 [0, tab_h + tab_out], [-10, tab_h + tab_out + 10]]);
}

// Tab outline at one corner of the back plate in the XZ plane:
// sx = -1 left / +1 right, sz = -1 bottom / +1 top.
module corner_tab_2d(sx, sz) {
    xe = sx < 0 ? -wall : inner_w + wall;
    ze = sz < 0 ? bot_z : top_z;
    translate([xe, ze]) mirror([sx < 0 ? 1 : 0, 0]) mirror([0, sz > 0 ? 1 : 0])
        tab_2d();
}

// Swings a tab on side sx back by tab_angle, hinged on the vertical line
// where the front face of the plate meets its side edge.
module tab_frame(sx) {
    xe = sx < 0 ? -wall : inner_w + wall;
    translate([xe, 0, 0]) rotate([0, 0, -sx * tab_angle]) translate([-xe, 0, 0])
        children();
}

// Places a 3D child on each tab's hole center, square to the tab.
module at_holes() {
    for (sx = [-1, 1], sz = [-1, 1]) {
        xe = sx < 0 ? -wall : inner_w + wall;
        ze = sz < 0 ? bot_z : top_z;
        tab_frame(sx)
            translate([xe + sx * tab_out / 2, 0, ze - sz * tab_h / 2]) children();
    }
}

module back_plate() {
    plate_piece() translate([-wall, bot_z]) square([outer_w, top_z - bot_z]);
    for (sx = [-1, 1], sz = [-1, 1]) {
        xe = sx < 0 ? -wall : inner_w + wall;
        difference() {
            tab_frame(sx) plate_piece() corner_tab_2d(sx, sz);
            // the part of the tab buried in the plate swings forward when
            // angled; trim it back flush with the front of the plate
            translate([sx < 0 ? xe : xe - 20, 0, bot_z - 1])
                cube([20, 10, top_z - bot_z + 2]);
        }
    }
}

module tab_holes() {
    at_holes() {
        translate([0, -back_t - eps, 0]) rotate([-90, 0, 0])
            cylinder(h = back_t + 2 * eps, d = screw_d);
        // countersink opens toward the front, where the screw head goes
        cs = (head_d - screw_d) / 2;
        translate([0, -cs, 0]) rotate([-90, 0, 0])
            cylinder(h = cs + eps, d1 = screw_d, d2 = head_d + 2 * eps);
    }
}

// --- box -------------------------------------------------------------------

module walls() {
    difference() {
        translate([0, 0, -floor_t])
            rounded_slab(inner_h + floor_t + eps, r_bot = edge_r)
                front_round_rect(-wall, -back_t, inner_w + wall, inner_d + wall, corner_r);
        // chamber
        translate([0, 0, open_bottom ? -1 : 0])
            linear_extrude(inner_h + 2)
                front_round_rect(0, 0, inner_w, inner_d, corner_r - wall);
        // entry slot, with rounded top corners
        translate([0, inner_d + wall + 1, 0]) rotate([90, 0, 0])
            linear_extrude(wall + 2)
                offset(r = slot_r) offset(delta = -slot_r)
                    translate([0, -50]) square([inner_w, entry_h + 50]);
    }
}

module roof() {
    translate([0, 0, inner_h])
        rounded_slab(roof_t, r_top = roof_edge_r, r_bot = edge_r)
            front_round_rect(-wall - side_oh, -back_t,
                             inner_w + wall + side_oh, inner_d + wall + overhang, roof_r);
}

// One 45-degree V groove running along X, cut into a face at y = 0 going -Y.
module groove(len) {
    rotate([90, 0, 90]) linear_extrude(len)
        polygon([[eps, -groove_depth - eps], [eps, groove_depth + eps], [-groove_depth, 0]]);
}

module back_grooves() {
    for (z = [bot_z + groove_pitch : groove_pitch : inner_h - groove_pitch])
        translate([0, 0, z]) groove(inner_w);
}

module front_grooves() {
    for (z = [entry_h + slot_r + groove_pitch : groove_pitch : inner_h - groove_pitch])
        translate([0, inner_d, z]) mirror([0, 1, 0]) groove(inner_w);
}

module bat_box() {
    difference() {
        union() {
            back_plate();
            walls();
            roof();
        }
        back_grooves();
        front_grooves();
        tab_holes();
        bat_engraving();
    }
}

color(print_color) {
    if (part == "assembled") {
        bat_box();
    } else if (part == "print") {
        // upside down, roof on the bed
        translate([0, 0, top_z]) rotate([180, 0, 0]) bat_box();
    } else if (part == "section") {
        // cut through the middle to show the grooves and entry slot
        difference() {
            bat_box();
            translate([inner_w / 2, -50, bot_z - 10]) cube([200, 300, 400]);
        }
    }
}
