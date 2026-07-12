`timescale 1ns/1ps
module oem_sorter#(parameter N=4)(
  input  wire [N-1:0] a0,a1,a2,a3,b0,b1,b2,b3,
  output wire [N-1:0] s0,s1,s2,s3,s4,s5,s6,s7
);
  // even
  wire [N-1:0] ee0,ee1,eo0,eo1;   // even evens, even odds intermediate
  wire [N-1:0] se0,se1,se2,se3;

  cas_a e_evens(a0,b0,ee0,ee1);
  cas_a e_odds (a2,b2,eo0,eo1);
  assign se0 = ee0;
  assign se3 = eo1;
  cas_a e_mid(eo0,ee1,se1,se2);

  // odd
  wire [N-1:0] oe0,oe1,oo0,oo1;
  wire [N-1:0] so0,so1,so2,so3;

  cas_a o_evens(a1,b1,oe0,oe1);
  cas_a o_odds (a3,b3,oo0,oo1);
  assign so0 = oe0;
  assign so3 = oo1;
  cas_a o_mid(oo0,oe1,so1,so2);

 //output
  assign s0 = se0;
  assign s7 = so3;
  cas_a final1(so0,se1,s1,s2);
  cas_a final2(so1,se2,s3,s4);
  cas_a final3(so2,se3,s5,s6);
endmodule
