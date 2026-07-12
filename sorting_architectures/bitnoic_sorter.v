module bitonic_sorter#(parameter N=4)(
  input wire [N-1:0] a0,a1,a2,a3,b0,b1,b2,b3,
  output reg [N-1:0] s0,s1,s2,s3,s4,s5,s6,s7

);
  wire [N-1:0] c0,c1,c2,c3,c4,c5,c6,c7;
  wire [N-1:0] d0,d1,d2,d3,d4,d5,d6,d7;
  //level 1
  cas_a asc1(a0,b0,c0,c4);
  cas_a asc2(a1,b1,c1,c5);
  cas_a asc3(a2,b2,c2,c6);
  cas_a asc4(a3,b3,c3,c7);
  //level 2
  cas_a asc5(c0,c2,d0,d2);
  cas_a asc6(c1,c3,d1,d3);
  cas_a asc7(c4,c6,d4,d6);
  cas_a asc8(c5,c7,d5,d7);
  //output
  cas_a asc9(d0,d1,s0,s1);
  cas_a asc10(d2,d3,s2,s3);
  cas_a asc11(d4,d5,s4,s5);
  cas_a asc12(d6,d7,s6,s7);
endmodule
