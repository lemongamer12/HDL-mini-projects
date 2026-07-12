module cas_a#(parameter N=4)(
  input wire [N-1:0] a,b,
  output reg [N-1:0] out_up,out_bottom);
  always@(*)begin 
    if(a>b)begin
      out_up=b;
      out_bottom=a;
    end
    else begin
      out_up=a;
      out_bottom=b;
    end
  end
endmodule
