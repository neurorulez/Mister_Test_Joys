//Control module for DB15 Splitter of Antonio Villena by Aitor Pelaez (NeuroRulez)
//Based on the ZXDOS module written by me too.
//
module joy_db15 
(
 input  clk,      //Reloj de Entrada sobre 48-50Mhz
 output JOY_CLK,
 output JOY_LOAD,  
 input  JOY_DATA, 
 output [15:0] joystick1,
 output [15:0] joystick2
);
//Gestion de Joystick
reg [7:0] JCLOCKS = 8'h00;   //[3:0] Seria 3Mhz desde 50Mhz
assign JOY_CLK = JCLOCKS[7]; //con 3 Funciona = 3Mhz
always @(posedge clk) begin 
   JCLOCKS <= JCLOCKS + 8'd1;
end
wire joy_ena = (JCLOCKS == 8'h00);

reg [15:0] joy1  = 16'hFFFF, joy2  = 16'hFFFF;
reg [4:0]joy_count = 5'd0;
   
assign JOY_LOAD = ~(joy_count == 5'd0);

always @(posedge clk) begin
  if (joy_ena == 1'b1) begin
	joy_count <= joy_count + 5'd1;
    case (joy_count)
        5'd0  : joy1[7]  <= JOY_DATA;  //P1 D
        5'd1  : joy1[6]  <= JOY_DATA;  //P1 C
        5'd2  : joy1[5]  <= JOY_DATA;  //P1 B
        5'd3  : joy1[4]  <= JOY_DATA;  //P1 A
        5'd4  : joy1[0]  <= JOY_DATA;  //P1 Derecha
        5'd5  : joy1[1]  <= JOY_DATA;  //P1 Izquierda
        5'd6  : joy1[2]  <= JOY_DATA;  //P1 Abajo
        5'd7  : joy1[3]  <= JOY_DATA;  //P1 Arriba
        5'd8  : joy2[0]  <= JOY_DATA;  //  P2 Derecha
        5'd9  : joy2[1]  <= JOY_DATA;  //  P2 Izquierda
        5'd10 : joy2[2]  <= JOY_DATA;  //  P2 Abajo
        5'd11 : joy2[3]  <= JOY_DATA;  //  P2 Arriba
        5'd12 : joy1[9]  <= JOY_DATA;  //P1 F 
        5'd13 : joy1[8]  <= JOY_DATA;  //P1 E 
        5'd14 : joy1[11] <= JOY_DATA;  //P1 Select
        5'd15 : joy1[10] <= JOY_DATA;  //P1 Start
        5'd16 : joy2[9]  <= JOY_DATA;  //  P2 F
        5'd17 : joy2[8]  <= JOY_DATA;  //  P2 E 
        5'd18 : joy2[11] <= JOY_DATA;  //  P2 Select
        5'd19 : joy2[10] <= JOY_DATA;  //  P2 Start
        5'd20 : joy2[7]  <= JOY_DATA;  //  P2 D
        5'd21 : joy2[6]  <= JOY_DATA;  //  P2 C
        5'd22 : joy2[5]  <= JOY_DATA;  //  P2 B
        5'd23 : joy2[4]  <= JOY_DATA;  //  P2 A
		default : ;
    endcase              
  end
end
//----LS FEDCBAUDLR
assign joystick1[15:0] = ~joy1;
assign joystick2[15:0] = ~joy2;

endmodule