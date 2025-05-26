`timescale 100ps/10ps

module triangle(clk, reset, nt, xi, yi, busy, po, xo, yo);
input        clk, reset, nt;
input  [2:0] xi, yi;
output       busy, po;
output [2:0] xo, yo;

reg busy, po;
reg [4:0] state, next_state; // State machine: current state and next state
reg [6:0] x_cor[0:2];        // Triangle vertex X-coordinate storage array
reg [6:0] y_cor[0:2];        // Triangle vertex Y-coordinate storage array
reg [1:0] s0_count;          // s0 state counter: for receiving 3 vertex coordinates
reg s1_count;                // s1 state counter: controls initialization completion
reg s2_count;                // s2 state counter: controls coordinate evaluation completion
reg s7_count;                // s7 state counter: controls end state
reg [4:0] horiz;             // Horizontal distance
reg [3:0] out_count;         // Output counter: current scanline Y-coordinate
reg signed [8:0] a[0:1];     // Linear equation coefficient a: Y-vectors of two edges
reg signed [8:0] b[0:1];     // Linear equation coefficient b: negative X-vectors of two edges
reg signed [8:0] c[0:1];     // Linear equation coefficient c: constant terms of two edges
reg [3:0] ep, save_ep;       // Edge parameter: X-coordinate of scanline-edge intersection
reg signed [7:0] value;      // Linear equation evaluation: determines if point is inside triangle
reg [1:0] o_idx;             // Output index: tracks current edge being processed (0, 1, 2)
reg [2:0] xo, yo;            // Output coordinates: current pixel X, Y coordinates
reg loc;                     // Location flag: determines relative position of x_cor[1] vs x_cor[0]
reg [3:0] start;             // Start point: starting X-coordinate of current scanline

parameter s0=5'd0,s1=5'd1,s2=5'd2,s3=5'd3,s4=5'd4,s5=5'd5,s6=5'd6,s7=5'd7;

integer i,j;

//state,next_state
always @(posedge clk or posedge reset)begin
    if(reset) state<=s0;
    else state<=next_state;
end

always @(*)begin
    case(state)
        s0:next_state=(s0_count==2'd3)?s1:s0;
        s1:next_state=(s1_count==1'b1)?s2:s1;
        s2:next_state=(out_count==y_cor[0]||out_count==y_cor[1]||out_count==y_cor[2])?s5:((s2_count==1'b1)?((value==8'd0)?s5:((value[7]==1'b0)?s3:s4)):s2);
        s3:next_state=(o_idx==2'd2)?s5:s2;
        s4:next_state=(o_idx==2'd1)?s5:s2;
        s5:next_state=(out_count==y_cor[0]||out_count==y_cor[2])?s6:((loc==1'b0)?((out_count==y_cor[1])?((start==x_cor[1])?s6:s5):((start==ep)?s6:s5)):((start==x_cor[0])?s6:s5));
        s6:next_state=(out_count==y_cor[2])?s7:s2;
        s7:next_state=(s7_count==1'b1)?s0:s7;
        default:next_state=s0;
    endcase
end

//busy
always @(posedge clk or posedge reset)begin
    if(reset) busy<=1'b0;
    else begin
        if(state==s7) busy<=1'b0;
        else if(nt==1'b0) busy<=1'b1;
        else busy<=1'b0;
    end
end

//s0_count
always @(posedge clk or posedge reset)begin
    if(reset) s0_count<=2'd0;
    else begin
        if(state==s7) s0_count<=2'd0;
        else s0_count<=s0_count+2'd1;
    end
end

//s1_count
always @(posedge clk or posedge reset)begin
    if(reset)begin
        s1_count<=1'b0;
    end
    else begin
        if(state==s1) s1_count<=1'b1;
        else s1_count<=1'b0;
    end
end

//s2_count
always @(posedge clk or posedge reset)begin
    if(reset)begin
        s2_count<=1'b0;
    end
    else begin
        if(state==s2) s2_count<=1'b1;
        else s2_count<=1'b0;
    end
end

//s7_count
always @(posedge clk or posedge reset)begin
    if(reset)begin
        s7_count<=1'b0;
    end
    else begin
        if(state==s7) s7_count<=1'b1;
        else s7_count<=1'b0;
    end
end

//loc
always @(posedge clk or posedge reset)begin
    if(reset)begin
        loc<=1'b0;
    end
    else begin
        if(state==s1)begin
            if(x_cor[1]>x_cor[0]) loc<=1'b0;
            else loc<=1'b1;
        end
    end
end

//a
always @(posedge clk or posedge reset)begin
    if(reset)begin
        for(i=0;i<2;i=i+1)begin
            a[i]<=9'd0;
        end
    end
    else begin
        case(state)
            s1:begin
                if(loc==1'b0)begin
                    a[0]<=($signed(y_cor[1])-$signed(y_cor[0]));
                    a[1]<=($signed(y_cor[2])-$signed(y_cor[1]));
                end
                else begin
                    a[0]<=($signed(y_cor[1])-$signed(y_cor[0]));
                    a[1]<=(~($signed(y_cor[2])-$signed(y_cor[1])))+9'd1;
                end
            end
        endcase
    end
end

//b
always @(posedge clk or posedge reset)begin
    if(reset)begin
        for(i=0;i<2;i=i+1)begin
            b[i]<=9'd0;
        end
    end
    else begin
        case(state)
            s1:begin
                if(loc==1'b0)begin
                    b[0]<=(~($signed(x_cor[1])-$signed(x_cor[0])))+9'd1;
                    b[1]<=(~($signed(x_cor[2])-$signed(x_cor[1])))+9'd1;
                end
                else begin
                    b[0]<=(~($signed(x_cor[1])-$signed(x_cor[0])))+9'd1;
                    b[1]<=($signed(x_cor[2])-$signed(x_cor[1]));
                end
            end
        endcase
    end
end

//c
always @(posedge clk or posedge reset)begin
    if(reset)begin
        for(i=0;i<2;i=i+1)begin
            c[i]<=9'd0;
        end
    end
    else begin
        case(state)
            s1:begin
                if(loc==1'b0)begin
                    c[0]<=($signed(y_cor[0]*x_cor[1])-$signed(y_cor[1]*x_cor[0]));
                    c[1]<=($signed(y_cor[1]*x_cor[2])-$signed(y_cor[2]*x_cor[1]));
                end
                else begin
                    c[0]<=($signed(y_cor[0]*x_cor[1])-$signed(y_cor[1]*x_cor[0]));
                    c[1]<=(~($signed(y_cor[1]*x_cor[2])-$signed(y_cor[2]*x_cor[1])))+9'd1;
                end
            end
        endcase
    end
end

//x_cor
always @(posedge clk or posedge reset)begin
    if(reset)begin
        for(i=0;i<3;i=i+1)begin
            x_cor[i]<=7'd0;
        end
    end
    else begin
        case(state)
            s0:begin
                x_cor[s0_count]<=xi;
            end
        endcase
    end
end

//y_cor
always @(posedge clk or posedge reset)begin
    if(reset)begin
        for(i=0;i<3;i=i+1)begin
            y_cor[i]<=7'd0;
        end
    end
    else begin
        case(state)
            s0:begin
                y_cor[s0_count]<=yi;
            end
        endcase
    end
end

//horiz
always @(posedge clk or posedge reset)begin
    if(reset) begin
        horiz<=5'd0;
    end
    else begin
        case(state)
            s1:begin
                horiz<=(x_cor[1]-x_cor[0]);
            end
        endcase
    end
end

//out_count
always @(posedge clk or posedge reset)begin
    if(reset)begin
        out_count<=4'd0;
    end
    else begin
        case(state)
            s1:out_count<=y_cor[0];
            s6:out_count<=out_count+4'd1;
        endcase
    end
end

//ep
always @(posedge clk or posedge reset)begin
    if(reset)begin
        ep<=4'd0;
    end
    else begin
        if(loc==1'b0)begin
            if(state==s6) ep<=save_ep;
            else if(state==s3)begin
                if(out_count<y_cor[1])begin
                    if(o_idx==2'd2) ep<=ep;
                    else ep<=ep+4'd1;
                end
                else ep<=ep-4'd1;
            end
            else if(state==s4)begin
                if(out_count<y_cor[1]) ep<=ep-4'd1;
                else begin
                    if(o_idx==2'd1) ep<=ep;
                    else ep<=ep+4'd1;
                end
            end
            else ep<=ep;
        end
        else begin
            if(state==s6) ep<=save_ep;
            else if(state==s3)begin
                if(out_count<y_cor[1])begin
                    if(o_idx==2'd2) ep<=ep;
                    else ep<=ep-4'd1;
                end
                else ep<=ep+4'd1;
            end
            else if(state==s4)begin
                if(out_count<y_cor[1]) ep<=ep+4'd1;
                else begin
                    if(o_idx==2'd1) ep<=ep;
                    else ep<=ep-4'd1;
                end
            end
            else ep<=ep;
        end
    end
end

//o_idx
always @(posedge clk or posedge reset)begin
    if(reset)begin
        o_idx<=2'd0;
    end
    else begin
        if(state==s3) o_idx<=2'd1;
        else if(state==s4) o_idx<=2'd2;
        else if(state==s5) o_idx<=2'd0;
    end
end

//save_ep
always @(posedge clk or posedge reset)begin
    if(reset)begin
        save_ep<=4'd0;
    end
    else begin
        if(state==s1) save_ep<=(x_cor[0]+x_cor[1])>>1;
    end
end

//value
always @(posedge clk or posedge reset)begin
    if(reset)begin
        value<=8'd0;
    end
    else begin
        if(state==s2) begin
            if(out_count==y_cor[0]||out_count==y_cor[1]||out_count==y_cor[2]) value<=8'd0;
            else if(out_count<y_cor[1]) begin
                value<=(a[0]*$signed(ep))+(b[0]*$signed(out_count))+c[0];
            end
            else begin
                value<=(a[1]*$signed(ep))+(b[1]*$signed(out_count))+c[1];
            end
        end
    end
end

//po
always @(posedge clk)begin
    if(state==s5) po<=1'b1;
    else po<=1'b0;
end

//start
always @(posedge clk)begin
    if(state==s5) start<=start+4'd1;
    else begin
        if(loc==1'b0) start<=x_cor[0];
        else begin
            if(out_count==y_cor[1]) start<=x_cor[1];
            else start<=ep;
        end
    end
end

//xo
always @(posedge clk or posedge reset)begin
    if(reset)begin
        xo<=3'd0;
    end
    else begin
        if(state==s5)begin
            if(out_count==y_cor[0]) xo<=x_cor[0];
            else if(out_count==y_cor[2]) xo<=x_cor[2];
            else xo<=start;
        end
    end
end

//yo
always @(posedge clk or posedge reset)begin
    if(reset)begin
        yo<=3'd0;
    end
    else begin
        if(state==s5)begin
            if(out_count==y_cor[0]) yo<=y_cor[0];
            else if(out_count==y_cor[2]) yo<=y_cor[2];
            else yo<=out_count;
        end
    end
end

endmodule