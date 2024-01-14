//==========================================
module  nco (i_clk,
             i_num,
             o_clk,
             i_rstn);

output              o_clk   ;

input   [31:0]      i_num   ;
input               i_clk   ;
input               i_rstn  ;

reg     [31:0]      cnt     ;
reg                 o_clk   ;

always @(posedge i_clk or negedge i_rstn) begin
    if(i_rstn == 1'b0) begin
        cnt     <= 32'd0    ;
        o_clk   <= 1'd0     ;
    end else begin
        if(cnt >= i_num/2-1) begin
            cnt     <= 32'd0    ;
            o_clk   <= ~ o_clk  ;
        end else begin
            cnt     <= cnt + 1'b1;
        end
    end
end

endmodule






//-==============================================
module  double_fig_sep(
                        o_left,
                        o_right,
                        i_double_fig);

output  [3:0]   o_left          ;
output  [3:0]   o_right         ;  

input   [5:0]   i_double_fig    ;

assign o_left   =   i_double_fig / 10 ;
assign o_right  =   i_double_fig % 10 ;

endmodule




//===========================================
module fnd_dec ( o_seg,
                 i_num  );

output  [6:0]   o_seg   ;
input   [3:0]   i_num   ;

//using case
reg     [6:0]  o_seg    ;

always @(*) begin
    case (i_num)
            //i_num == 0~3
            4'b0000 : o_seg = 7'b111_1110;//LED = '0'
            4'b0001 : o_seg = 7'b011_0000;//LED = '1'
            4'b0010 : o_seg = 7'b110_1101;//LED = '2'
            4'b0011 : o_seg = 7'b111_1001;//LED = '3'
            //i_num == 4~7
            4'b0100 : o_seg = 7'b011_0011;//LED = '4'
            4'b0101 : o_seg = 7'b101_1011;//LED = '5'
            4'b0110 : o_seg = 7'b101_1111;//LED = '6'
            4'b0111 : o_seg = 7'b111_0000;//LED = '7'
            //i_num == 8~11
            4'b1000 : o_seg = 7'b111_1111;//LED = '8'
            4'b1001 : o_seg = 7'b111_0011;//LED = '9'
            4'b1010 : o_seg = 7'b111_0111;//LED = 'A'
            4'b1011 : o_seg = 7'b111_1111;//LED = 'B'
            //i_num == 12~15
            4'b1100 : o_seg = 7'b100_1110;//LED = 'C'
            4'b1101 : o_seg = 7'b111_1110;//LED = 'D'
            4'b1110 : o_seg = 7'b100_1111;//LED = 'E'
            4'b1111 : o_seg = 7'b100_0111;//LED = 'F'
    endcase
end

endmodule




//===========================================
module  led_disp(   o_seg,
                    o_seg_dp,
                    o_seg_enb,
                    i_six_digit_seg,
                    i_six_dp,
                    clk,
                    rst_n               );

output  [5:0]   o_seg_enb               ;
output          o_seg_dp                ;
output  [6:0]   o_seg                   ;

input   [41:0]  i_six_digit_seg         ;
input   [5:0]   i_six_dp                ;
input           clk                     ;
input           rst_n                   ;

wire            gen_clk                 ;

nco             u_nco(  .o_clk (gen_clk             ),
                        .i_num (100000              ),  
                        .i_clk (clk                 ),
                        .i_rstn(rst_n               )   );


reg     [3:0]   cnt_common_node                 ;
always @(posedge gen_clk or negedge rst_n) begin
        if(rst_n == 1'b0)   begin
                cnt_common_node <= 4'b0;
        end else begin
                if(cnt_common_node >= 4'd5) begin
                        cnt_common_node <= 4'd0;
                end else begin
                        cnt_common_node <= cnt_common_node + 1'b1;
                end
        end
end



reg     [5:0]   o_seg_enb           ;
always @(cnt_common_node) begin
    case (cnt_common_node)
            4'd0 : o_seg_enb    = 6'b111110;
            4'd1 : o_seg_enb    = 6'b111101;
            4'd2 : o_seg_enb    = 6'b111011;
            4'd3 : o_seg_enb    = 6'b110111;
            4'd4 : o_seg_enb    = 6'b101111;
            4'd5 : o_seg_enb    = 6'b011111;
    endcase
end

reg             o_seg_dp            ;
always  @(cnt_common_node) begin
    case (cnt_common_node)
            4'd0 : o_seg_dp     = i_six_dp[0];
            4'd1 : o_seg_dp     = i_six_dp[1];
            4'd2 : o_seg_dp     = i_six_dp[2];
            4'd3 : o_seg_dp     = i_six_dp[3];
            4'd4 : o_seg_dp     = i_six_dp[4];
            4'd5 : o_seg_dp     = i_six_dp[5];
    endcase
end

reg     [6:0]   o_seg               ;
always  @(cnt_common_node)  begin
    case (cnt_common_node)
            4'd0 : o_seg    = i_six_digit_seg[6:0];
            4'd1 : o_seg    = i_six_digit_seg[13:7];
            4'd2 : o_seg    = i_six_digit_seg[20:14];
            4'd3 : o_seg    = i_six_digit_seg[27:21];
            4'd4 : o_seg    = i_six_digit_seg[34:28];
            4'd5 : o_seg    = i_six_digit_seg[41:35];
    endcase
end

endmodule




//==============================================
module debounce ( o_sw,
                  i_sw,
                  clk  );


output  o_sw        ;
input   i_sw        ;  
input   clk         ;


reg     dly1_sw     ;

always  @(posedge clk) begin
        dly1_sw <= i_sw;
end

reg     dly2_sw     ;
always  @(posedge clk) begin
    dly2_sw <= dly1_sw;
end

assign o_sw = dly1_sw | ~dly2_sw;

endmodule



//========================================
module  hms_cnt_up( o_hms_cnt,
                    i_max_cnt,
                    o_max_hit,
                    clk,
                    rst_n       );

output   [5:0]  o_hms_cnt       ;
output          o_max_hit       ;

input    [5:0]  i_max_cnt       ;
input           clk             ;
input           rst_n           ;

reg     [5:0]   o_hms_cnt       ;
reg             o_max_hit       ;


always @(posedge clk or negedge rst_n) begin
    if(rst_n==1'b0) begin
        o_hms_cnt <= 6'd0;
        o_max_hit <= 1'b0;
    end else begin
        if(o_hms_cnt >= i_max_cnt) begin
            o_hms_cnt <= 6'd0;
            o_max_hit <= 1'b1;
        end else begin
            o_hms_cnt <= o_hms_cnt + 1'b1   ;
            o_max_hit <= 1'b0               ;
        end
    end
end

endmodule


//============================================
module updw_hms (   o_hms_cnt,
                    o_max_or_min_hit,
                    i_option,
                    i_min_cnt,
                    i_max_cnt,
                    clk,
                    clk_50MHz,
                    rst_n                );


output  [5:0]   o_hms_cnt           ;
output          o_max_or_min_hit    ;

input           i_option            ;
input           clk                 ;
input           rst_n               ;
input   [5:0]   i_max_cnt           ;
input   [5:0]   i_min_cnt           ;
input           clk_50MHz           ;
reg     [5:0]   o_hms_cnt           ;
reg             o_max_or_min_hit_pre;

reg             o_max_or_min_hit_en ;
reg				zero_cnt;

// 첫번째 타이머 사용 시 00:00:00이 되면서 만들어진 분 부분 min_hit이 계속 1에서 내려오지 않아서
// 타이머를 시작할때마다 시부분 down count가 동작하는 현상을 해결하기위한 o_max_or_min_hit_en 신호 제작 
always @(posedge clk_50MHz) begin
        if(zero_cnt==1'd0) begin
            o_max_or_min_hit_en <=1'd1;
        end else begin
            if(clk==1'd1) begin
                o_max_or_min_hit_en <=1'd1;
            end else begin
                o_max_or_min_hit_en <=1'd0;
            end
        end
end

always @(posedge clk ) begin
    if(i_option == 1'b0) begin           
        if(o_hms_cnt >= i_max_cnt) begin        //when Timer STOP, upcnt사용
            o_hms_cnt <= 6'd0;                  //restart at 0
            o_max_or_min_hit_pre <= 1'b1;       //MAX hit
        end else begin
            o_hms_cnt <= o_hms_cnt + 1'b1   ;
            o_max_or_min_hit_pre <= 1'b0        ;
        end            
    end else begin                          
        if(o_hms_cnt <= i_min_cnt) begin        //when Timer START, dwcnt사용 
            o_hms_cnt <= 6'd59          ;       //restart at 59
            o_max_or_min_hit_pre <= 1'd1    ;   //MIN hit     
            zero_cnt  <= 1'd1;   
        end else begin
            o_max_or_min_hit_pre <= 1'b0     ;
            o_hms_cnt <= o_hms_cnt - 1   ;
            zero_cnt <= 1'd0;
        end
    end  
end

assign o_max_or_min_hit = (o_max_or_min_hit_en) && (o_max_or_min_hit_pre)   ;

endmodule




//==============================================
module  buzz(   o_buzz,
                i_buzz_en,
                clk,
                rst_n       );

output      o_buzz      ;

input       i_buzz_en   ;
input       clk         ;
input       rst_n       ;

wire        clk_beat    ;


parameter       C = 191113  ;
parameter       D = 170262  ;
parameter       E = 151686  ;
parameter       F = 143173  ;
parameter       G = 63776   ;
parameter       A = 56818   ;
parameter       B = 50619   ;


nco     u_nco_beat  (   .o_clk  (clk_beat       ),
                        .i_num  (25000000       ),
                        .i_clk  (clk            ),
                        .i_rstn (rst_n          )   );


reg     [4:0]   cnt=0;
always  @(posedge clk_beat  or negedge rst_n) begin 
    if (rst_n == 1'b0) begin                        
        cnt <= 5'd0;
    end else begin
        if (cnt >= 5'd24) begin
            cnt <= 5'd0;
        end else if (i_buzz_en == 1'b1) begin
            cnt <= cnt + 1'd1;
        end else if (i_buzz_en == 1'b0) begin
            cnt <= 1'd0;
        end
    end
end




reg [31:0]  nco_num     ;
always  @(*) begin
    case (cnt)
        5'd00: nco_num = E  ;
        5'd01: nco_num = D  ;
        5'd02: nco_num = C  ;
        5'd03: nco_num = D  ;
        5'd04: nco_num = E  ;
        5'd05: nco_num = E  ;
        5'd06: nco_num = E  ;

        5'd07: nco_num = D  ;
        5'd08: nco_num = D  ;
        5'd09: nco_num = D  ;

        5'd10: nco_num = E  ;
        5'd11: nco_num = E  ;
        5'd12: nco_num = E  ;

        5'd13: nco_num = E  ;
        5'd14: nco_num = D  ;
        5'd15: nco_num = C  ;
        5'd16: nco_num = D  ;
        5'd17: nco_num = E  ;
        5'd18: nco_num = E  ;
        5'd19: nco_num = E  ;

        5'd20: nco_num = D  ;
        5'd21: nco_num = D  ;
        5'd22: nco_num = E  ;
        5'd23: nco_num = C  ;
        5'd24: nco_num = D  ;
    endcase
end


wire    buzz        ;
nco     u_nco_buzz(     .o_clk      (buzz       ),
                        .i_num      (nco_num    ),
                        .i_clk      (clk        ),
                        .i_rstn     (rst_n      )    )  ;

assign  o_buzz  = buzz  & i_buzz_en;

endmodule




// ========================================================
module blink    (   i_node0,
                    i_node1,
                    i_node2,
                    i_node3,
                    i_node4,
                    i_node5,
                    i_position,
                    i_mode,
                    i_start_stop,

                    clk,
                    rst_n,
                    
                    o_seg0,
                    o_seg1,
                    o_seg2,
                    o_seg3,
                    o_seg4,
                    o_seg5      );

parameter   MODE_CLOCK =    2'b00       ;
parameter   MODE_SETUP =    2'b01       ;
parameter   MODE_ALARM =    2'b10       ;
parameter   MODE_TIMER =    2'b11       ;
parameter   POS_SEC    =    2'b00       ;
parameter   POS_MIN    =    2'b01       ;
parameter   POS_HOUR   =    2'b10       ;

parameter	STOP	   =    1'd0        ;
parameter   START	   =    1'd1        ;

input   [6:0]   i_node0         ;
input   [6:0]   i_node1         ;
input   [6:0]   i_node2         ;
input   [6:0]   i_node3         ;
input   [6:0]   i_node4         ;
input   [6:0]   i_node5         ;

input   [1:0]   i_position      ;
input   [1:0]   i_mode          ;
input           i_start_stop    ;
input           clk             ;
input           rst_n           ;

output  [6:0]   o_seg0          ;
output  [6:0]   o_seg1          ;
output  [6:0]   o_seg2          ;
output  [6:0]   o_seg3          ;
output  [6:0]   o_seg4          ;
output  [6:0]   o_seg5          ;





reg [31:0]  blink_cnt=0;

always @(posedge clk) begin
    if(blink_cnt >= 32'd50000000) begin
        blink_cnt <= 1'd0;
    end else begin
        blink_cnt <= blink_cnt + 1;
    end
end



reg [6:0] blink_node0;
reg [6:0] blink_node1;
reg [6:0] blink_node2;
reg [6:0] blink_node3;
reg [6:0] blink_node4;
reg [6:0] blink_node5;

//display가 0.5sec OFF -> 0.5sec ON 을 반복하도록 blink_node 제작 
always @(posedge clk or negedge rst_n) begin
    case(i_position)
        POS_SEC: begin
        blink_node0<=(blink_cnt<25000000)? i_node0 : 6'd0;
        blink_node1<=(blink_cnt<25000000)? i_node1 : 6'd0;
        end
        POS_MIN: begin
        blink_node2<=(blink_cnt<25000000)? i_node2 : 6'd0;
        blink_node3<=(blink_cnt<25000000)? i_node3 : 6'd0;
        end
        POS_HOUR: begin
        blink_node4<=(blink_cnt<25000000)? i_node4 : 6'd0;
        blink_node5<=(blink_cnt<25000000)? i_node5 : 6'd0;
        end
    endcase
    
end

reg [6:0] o_seg0;
reg [6:0] o_seg1;
reg [6:0] o_seg2;
reg [6:0] o_seg3;
reg [6:0] o_seg4;
reg [6:0] o_seg5;

always @(posedge clk or negedge rst_n) begin
    case(i_mode)
        // CLOCK MODE일 땐 Blink 효과 x 
        MODE_CLOCK: begin
                o_seg0 <= i_node0;
                o_seg1 <= i_node1;
                o_seg2 <= i_node2;
                o_seg3 <= i_node3;
                o_seg4 <= i_node4;
                o_seg5 <= i_node5;    
        end

        // TIMER MODE일 땐 STOP되었을때만 Blink되도록 설정 
        MODE_TIMER: begin
            case(i_start_stop)
                START: begin
                    o_seg0 <= i_node0;
                    o_seg1 <= i_node1;
                    o_seg2 <= i_node2;
                    o_seg3 <= i_node3;
                    o_seg4 <= i_node4;
                    o_seg5 <= i_node5;    
                end
                STOP: begin
                    case(i_position)
                        POS_SEC: begin
                        o_seg0 <= blink_node0;
                        o_seg1 <= blink_node1;
                        o_seg2 <= i_node2;
                        o_seg3 <= i_node3;
                        o_seg4 <= i_node4;
                        o_seg5 <= i_node5;
                        end

                        POS_MIN: begin
                        o_seg0 <= i_node0;
                        o_seg1 <= i_node1;
                        o_seg2 <= blink_node2;
                        o_seg3 <= blink_node3;
                        o_seg4 <= i_node4;
                        o_seg5 <= i_node5;
                        end

                        POS_HOUR: begin
                        o_seg0 <= i_node0;
                        o_seg1 <= i_node1;
                        o_seg2 <= i_node2;
                        o_seg3 <= i_node3;
                        o_seg4 <= blink_node4;
                        o_seg5 <= blink_node5;
                        end
                    endcase
                end
			   endcase
        end

        // SETUP MODE일 때 position에 따라 Blink되도록 설정 
        MODE_SETUP: begin
            case(i_position)
                POS_SEC: begin
                o_seg0 <= blink_node0;
                o_seg1 <= blink_node1;
                o_seg2 <= i_node2;
                o_seg3 <= i_node3;
                o_seg4 <= i_node4;
                o_seg5 <= i_node5;
                end

                POS_MIN: begin
                o_seg0 <= i_node0;
                o_seg1 <= i_node1;
                o_seg2 <= blink_node2;
                o_seg3 <= blink_node3;
                o_seg4 <= i_node4;
                o_seg5 <= i_node5;
                end

                POS_HOUR: begin
                o_seg0 <= i_node0;
                o_seg1 <= i_node1;
                o_seg2 <= i_node2;
                o_seg3 <= i_node3;
                o_seg4 <= blink_node4;
                o_seg5 <= blink_node5;
                end
            endcase
        end

        // ALARM MODE일 때 SET UP MODE와 마찬가지로 position에 따라 Blink되도록 설정 
        MODE_ALARM: begin
            case(i_position)
                POS_SEC: begin
                o_seg0 <= blink_node0;
                o_seg1 <= blink_node1;
                o_seg2 <= i_node2;
                o_seg3 <= i_node3;
                o_seg4 <= i_node4;
                o_seg5 <= i_node5;
                end

                POS_MIN: begin
                o_seg0 <= i_node0;
                o_seg1 <= i_node1;
                o_seg2 <= blink_node2;
                o_seg3 <= blink_node3;
                o_seg4 <= i_node4;
                o_seg5 <= i_node5;
                end

                POS_HOUR: begin
                o_seg0 <= i_node0;
                o_seg1 <= i_node1;
                o_seg2 <= i_node2;
                o_seg3 <= i_node3;
                o_seg4 <= blink_node4;
                o_seg5 <= blink_node5;
                end
            endcase        
        end

endcase
end


endmodule






// =======================================
//=========리모컨 수신 모듈 ir_rx==========
//========================================
module ir_rx(   o_data,
		        one_signal_separ,
                i_ir_rxb,
                clk,
                rst_n                   );

output  [31:0]  o_data              ;
output		    one_signal_separ    ;   //리모컨의 같은 버튼이 여러번 눌렸을때 신호간의 구분을 위해 지정한 출력 

input           i_ir_rxb            ;
input           clk                 ;
input           rst_n               ;


parameter   IDLE        = 3'b000     ;
parameter   LEADCODE    = 3'b001     ;
parameter   COSTOMCODE  = 3'b010     ;
parameter   DATACODE    = 3'b011     ;
parameter   COMPLETE    = 3'b100     ;


wire    clk_1M                  ;

nco     nco_1M( .o_clk  (clk_1M     ),
                .i_num  (50         ),
                .i_clk  (clk        ),
                .i_rstn (rst_n      )   );


wire    ir_rx                   ;
assign  ir_rx = ~i_ir_rxb       ;


reg     [1:0]   seq_rx          ;
always @(posedge clk_1M or negedge rst_n) begin
    if(rst_n == 1'b0) begin
        seq_rx <= 2'b00;
    end else begin
        seq_rx <= {seq_rx[0], ir_rx};
    end
end





//Count Signal Polarity

reg     [15:0]  cnt_h           ;
reg     [15:0]  cnt_l           ;

always @(posedge clk_1M or negedge rst_n) begin
    if (rst_n == 1'b0) begin
        cnt_h <= 16'd0  ;
        cnt_l <= 16'd0  ;
    end else begin
        case(seq_rx)
            2'b00   :   cnt_l <= cnt_l + 1      ;
            2'b01   : begin
                    cnt_l <= 16'd0              ;
                    cnt_h <= 16'd0              ;
            end
            2'b11   :	cnt_h <= cnt_h + 1      ;
        endcase
    end
end



reg     [2:0]   state		;
reg     [5:0]   cnt32		;
always @(posedge clk_1M or negedge rst_n) begin
    if (rst_n == 1'b0) begin
            state <= IDLE	;
            cnt32 <= 6'd0	;
    end else begin
        case (state)
                IDLE : begin
                        state <= LEADCODE   ;
                        cnt32 <= 6'd0   ;
                end
                LEADCODE: begin
                        if ( cnt_h >= 8500 && cnt_l >= 4000 ) begin
                                state <= COSTOMCODE   ;
                        end else begin
                                state <= LEADCODE   ;
                                
                        end
                end
                COSTOMCODE: begin
                        if (seq_rx == 2'b01 ) begin
                                cnt32 <= cnt32 + 1  ;
                        end else begin
                                cnt32 <= cnt32      ;
                        end
                        if (cnt32 >= 6'd16 && cnt_l >= 1000) begin
                                state <= DATACODE   ;
                        end else begin
                                state <= COSTOMCODE   ;
                        end
                end
                DATACODE: begin
                        if (seq_rx == 2'b01 ) begin
                                cnt32 <= cnt32 + 1  ;
                        end else begin
                                cnt32 <= cnt32      ;
                        end
                        if (cnt32 >= 6'd32 && cnt_l >= 1000) begin
                                state <= COMPLETE   ;
                        end else begin
                                state <= DATACODE   ;
                        end
                end
                COMPLETE: state <= IDLE             ;
        endcase
    end
end

reg     [31:0]      data            ;
reg     [31:0]      o_data          ;
always @(posedge clk_1M or negedge rst_n ) begin
    if (rst_n == 1'b0) begin
            data <= 32'd0           ;
    end else begin
        case (state)
                COSTOMCODE: begin
                    if (cnt_l >= 1000) begin
                        data [32-cnt32] <= 1'b1     ;
                    end else begin
                        data [32-cnt32] <= 1'b0     ;
                    end
                end
                DATACODE: begin
                    if (cnt_l >= 1000) begin
                        data [32-cnt32] <= 1'b1     ;
                    end else begin
                        data [32-cnt32] <= 1'b0     ;
                    end
                end
                COMPLETE: o_data <= data            ;
        endcase
	end
end


reg	one_signal_separ;

always @( posedge clk_1M or negedge rst_n ) begin
    if (rst_n == 1'b0) begin
            one_signal_separ <= 1'd0           ;
    end else begin
        case (state)
                DATACODE: begin
                    one_signal_separ <= 1'b1;   // one_signal_separ == state가 DATACODE일때만 1인 signal
                end
                COMPLETE: begin
                    one_signal_separ <= 1'b0;
				end
        endcase
	 end
end


endmodule



//=====================================================
//==ir_rx 모듈의 신호를 => i_sw 신호로 바꿔줄 중간 모듈==
//=====================================================
module remote_signal_into_i_sw (    o_sw0,
                                    o_sw1,
                                    o_sw2,
                                    o_sw3,

                                    clk,
					                rst_n,
                                    i_data,
					                one_signal_separ    );



output          o_sw0               ;
output          o_sw1               ;
output          o_sw2               ;
output          o_sw3               ;

input		    rst_n		        ;
input           clk                 ;
input   [31:0]  i_data              ;
input		    one_signal_separ	;

wire    [7:0]   datacode8bit        ;
assign          datacode8bit = i_data[15:8]    ; // remote controller의 신호 중 data code 8bit만 추출


reg             o_sw0   ;
reg             o_sw1   ;
reg             o_sw2   ;
reg             o_sw3   ;


reg [31:0]      sw_cnt=0;

always @(posedge clk) begin
    if(one_signal_separ == 1'b0) begin
        if(sw_cnt >= 32'd300000) begin
            sw_cnt <= 1'd0;
        end else begin
            sw_cnt <= sw_cnt + 1;
        end
    end else begin
        sw_cnt <= 1'd0;            //originally sw_cnt
    end   
end   



// 실제로 버튼을 누르는것같은 효과를 만드는 signal을 제작
// (버튼을 누르는 순간 1---> 0 ----> 1이 되는 기존의 스위치 방식을 모방), 따라서 이후의 모듈에 일체 수정이 없도록 함 
// MENU button == sw_0 에 대응
// ◀ button   == sw_1 에 대응
// ▲  button   == sw_2 에 대응 
// 전원 button == sw_3 에 대응 
always @(posedge clk) begin
	if(sw_cnt >= 32'd100) begin
	case(datacode8bit)
            //MENU to mode selection
	        8'b0100_0000: begin		    
            o_sw0 <= 1'b0;      //<== MENU button이 눌렸을 때 o_sw0출력을 순간 0으로 만듦
            o_sw1 <= 1'b1;
            o_sw2 <= 1'b1;
            o_sw3 <= 1'b1;
            end

            //left arrow to location
            8'b0001_0000: begin		
            o_sw0 <= 1'b1;
            o_sw1 <= 1'b0;      //<== ◀ button이 눌렸을 때 o_sw1출력을 순간 0으로 만듦      
            o_sw2 <= 1'b1;
            o_sw3 <= 1'b1;
            end

            //up arrow to upcount time
            8'b1010_0000: begin		
            o_sw0 <= 1'b1;
            o_sw1 <= 1'b1;
            o_sw2 <= 1'b0;      //<== ▲ button이 눌렸을 때 o_sw2출력을 순간 0으로 만듦
            o_sw3 <= 1'b1;
            end

            //power to alarm on/off
            8'b0000_0000: begin		
            o_sw0 <= 1'b1;
            o_sw1 <= 1'b1;
            o_sw2 <= 1'b1;
            o_sw3 <= 1'b0;      //<== 전원모양 button이 눌렸을 때 o_sw3출력을 순간 0으로 만듦
            end
        endcase
    	end else begin
        o_sw0 <= 1'b1;
        o_sw1 <= 1'b1;
        o_sw2 <= 1'b1;
        o_sw3 <= 1'b1;       
    	end

	
end


endmodule 
