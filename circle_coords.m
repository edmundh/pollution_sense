function [cx,cy]=circle_coords(centre_x, centre_y, r) 
t = 0 : .1 : 2*pi; 
cx = r * cos(t) + centre_x; 
cy = r * sin(t) + centre_y; 
end