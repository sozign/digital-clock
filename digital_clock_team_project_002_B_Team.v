///====================
///  Clock Controller
///====================

module  Controller( o_min_clk,
                    o_sec_clk,
                    o_hour_clk,
                    o_mode,
                    o_position,
                    o_alarm_min_clk,
                    o_alarm_sec_clk,
                    o_alarm_hour_clk,
                    o_timer_sec_clk,
                    o_timer_min_clk,
                    o_timer_hour_clk,
                    o_start_stop,
                    o_alarm_en,

                    clk,
                    i_max_hit_min,
                    i_max_hit_sec,
                    i_timer_sec_hit,
                    i_timer_min_hit,
                    i_sec,
                    i_min,
                    i_hour,
                    i_sw0,
                    i_sw1,
                    i_sw2,
                    i_sw3,
                    rst_n            );


parameter   MODE_CLOCK =    2'b00;
parameter   MODE_SETUP =    2'b01;
parameter   MODE_ALARM =    2'b10;
parameter   MODE_TIMER =    2'b11;
parameter   POS_SEC    =    2'b00;
parameter   POS_MIN    =    2'b01;
parameter   POS_HOUR   =    2'b10;

parameter   STOP        =   1'b0;
parameter   START       =   1'b1;


output          o_min_clk           ;
output          o_sec_clk           ;
output          o_hour_clk          ;

output  [1:0]   o_mode              ;
output  [1:0]   o_position          ;
output          o_start_stop        ;
output          o_alarm_sec_clk     ;
output          o_alarm_min_clk     ;
output          o_alarm_hour_clk    ;
output          o_alarm_en          ;
output          o_timer_sec_clk     ;
output          o_timer_min_clk     ;
output          o_timer_hour_clk    ;

input   clk                 ;
input   i_max_hit_min       ;
input   i_max_hit_sec       ;
input   i_timer_min_hit     ;
input   i_timer_sec_hit     ;
input   i_sw0               ;
input   i_sw1               ;
input   i_sw2               ;
input   i_sw3               ;
input   [5:0]   i_sec       ;
input   [5:0]   i_min       ;
input   [5:0]   i_hour      ;
input   rst_n               ;
wire    sw0                 ;
wire    sw1                 ;
wire    sw2                 ;
wire    sw3                 ;
wire    clk_slow            ;


nco     u_nco_db(   .o_clk  (clk_slow   ),
                    .i_num  (500000     ),
                    .i_clk  (clk        ),
                    .i_rstn (rst_n      )   );


debounce    u_debounce0(    .o_sw (sw0      ),
                            .i_sw (i_sw0    ),
                            .clk  (clk_slow )   );

debounce    u_debounce1(    .o_sw (sw1      ),
                            .i_sw (i_sw1    ),
                            .clk  (clk_slow )   );

debounce    u_debounce2(    .o_sw (sw2      ),
                            .i_sw (i_sw2    ),
                            .clk  (clk_slow )   );

debounce    u_debounce3(    .o_sw (sw3      ),
                            .i_sw (i_sw3    ),
                            .clk  (clk_slow )   );


reg     [1:0]   o_mode          ;
always @(posedge sw0  or negedge rst_n) begin
    if(rst_n == 1'b0) begin
        o_mode <= MODE_CLOCK;
    end else begin 
        if(o_mode>=MODE_TIMER) begin
            o_mode <= MODE_CLOCK;
        end else begin
            o_mode <= o_mode + 1'b1;
        end
    end
end

reg     [1:0]  o_position        ;
always @(posedge sw1 or negedge rst_n) begin
    if (rst_n == 1'b0) begin
        o_position <= POS_SEC;
    end else begin
        if (o_position >= POS_HOUR) begin
            o_position <= POS_SEC;
        end else begin
            o_position <= o_position + 1'b1;
        end
    end
end


reg     o_alarm_en  ;
always @(posedge sw3 or negedge rst_n) begin
    if(rst_n == 1'b0) begin
        o_alarm_en <= 1'b0;
    end else begin
        o_alarm_en <= o_alarm_en + 1'b1;
    end
end


reg         o_start_stop        ;
always  @(posedge sw3 or negedge rst_n) begin
    if(rst_n == 1'b0) begin
        o_start_stop <= STOP;
    end else begin
        if(o_mode == MODE_TIMER) begin
            if (o_start_stop >= START) begin
                o_start_stop <= STOP;
            end else begin
                o_start_stop <= o_start_stop + 1'b1;
            end
        end else begin
            o_start_stop <= STOP;
        end
    end
end

// MODE_TIMER에서 down count되다가 00:00:00 에서 멈추게 하기 위한 신호 제작 
reg     finish  ;
always  @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0) begin
        finish <= 1'b0;
    end else begin
        if( (i_sec== 6'd0 ) && (i_min == 6'd0) && (i_hour == 6'd0) ) begin
            finish <= 1'b1; // 00:00:00이 되었을때 finish 신호를 1로 인가 
        end else begin
        finish <= 1'b0;     // 다른 때에는 0이 default  
        end
    end    
end


wire    clk_1hz         ;
nco     u_nco_2(  .o_clk  (clk_1hz    ),
                  .i_num  (50000000   ),
                  .i_rstn (rst_n      ),
                  .i_clk  (clk        )   );


reg     o_sec_clk           ;
reg     o_min_clk           ;
reg     o_hour_clk          ;
reg     o_alarm_min_clk     ;
reg     o_alarm_sec_clk     ;
reg     o_alarm_hour_clk    ;
reg     o_timer_min_clk     ;
reg     o_timer_sec_clk     ;
reg     o_timer_hour_clk    ;

always  @(*) begin
    case(o_mode)
        MODE_CLOCK: begin
            o_sec_clk    <= clk_1hz            ;   
            o_min_clk    <= i_max_hit_sec      ;
            o_hour_clk   <= i_max_hit_min     ;
        end
        MODE_SETUP: begin
        case(o_position)
            POS_SEC: begin
                o_sec_clk  <= ~sw2   ;
                o_min_clk  <= 1'b0   ;
                o_hour_clk <= 1'b0   ;
            end
            POS_MIN: begin
                o_sec_clk  <= 1'b0   ;
                o_min_clk  <= ~sw2   ;
                o_hour_clk <= 1'b0   ;
            end
            POS_HOUR: begin
                o_sec_clk  <= 1'b0   ;
                o_min_clk  <= 1'b0   ;
                o_hour_clk <= ~sw2   ;
            end
        endcase
        end
        MODE_ALARM: begin
            case(o_position)
            POS_SEC:begin
                o_sec_clk  = clk_1hz         ;
                o_min_clk  = i_max_hit_sec   ;
                o_hour_clk = i_max_hit_min   ;
                o_alarm_sec_clk = ~sw2      ;
                o_alarm_min_clk = 1'b0      ;
                o_alarm_hour_clk= 1'b0      ;
            end
            POS_MIN:begin
                o_sec_clk = clk_1hz         ;
                o_min_clk = i_max_hit_sec   ;
                o_hour_clk = i_max_hit_min  ;
                o_alarm_sec_clk = 1'b0      ;
                o_alarm_min_clk = ~sw2      ;
                o_alarm_hour_clk= 1'b0      ;
            end
            POS_HOUR:begin
                o_sec_clk = clk_1hz         ;
                o_min_clk = i_max_hit_sec   ;
                o_hour_clk = i_max_hit_min  ;
                o_alarm_sec_clk = 1'b0      ;
                o_alarm_min_clk = 1'b0      ;
                o_alarm_hour_clk= ~sw2      ;
            end
            endcase
        end


        // TIMER MODE일때 
        //[START] -> sec hms 모듈의 input clk로 1Hz를 선택 
        // [STOP] -> sec hms 모듈의 input clk로 ~sw2를 선택 
        // 즉, start_stop 신호에 따라 input clk signal을 선택해주는 MUX를 포함시킴 
        MODE_TIMER: begin
            case(o_start_stop)
                START: begin
                    case(finish)
                        1'b1:begin
                            o_sec_clk  = clk_1hz                   ;
                            o_min_clk  = i_max_hit_sec             ;
                            o_hour_clk = i_max_hit_min             ;
                            o_timer_sec_clk = 1'b0                 ;
                            o_timer_min_clk = 1'b0                 ;
                            o_timer_hour_clk= 1'b0                 ;
                        end
                        1'b0:begin
                            o_sec_clk  = clk_1hz                   ;
                            o_min_clk  = i_max_hit_sec             ;
                            o_hour_clk = i_max_hit_min             ;
                            o_timer_sec_clk = clk_1hz              ;
                            o_timer_min_clk = i_timer_sec_hit      ;
                            o_timer_hour_clk= i_timer_min_hit      ;
                        end
                    endcase
                end 
                STOP: begin
                    case(o_position)
                        POS_SEC: begin
                            o_sec_clk  = clk_1hz                   ;
                            o_min_clk  = i_max_hit_sec             ;
                            o_hour_clk = i_max_hit_min             ;
                            o_timer_sec_clk = ~sw2                 ;
                            o_timer_min_clk = 1'b0                 ;
                            o_timer_hour_clk= 1'b0                 ;
                        end
                        POS_MIN: begin
                            o_sec_clk  = clk_1hz                ;
                            o_min_clk  = i_max_hit_sec          ;
                            o_hour_clk = i_max_hit_min          ;
                            o_timer_sec_clk = 1'b0              ;
                            o_timer_min_clk = ~sw2              ;
                            o_timer_hour_clk= 1'b0              ;
                        end
                        POS_HOUR:begin
                            o_sec_clk  = clk_1hz         ;
                            o_min_clk  = i_max_hit_sec   ;
                            o_hour_clk = i_max_hit_min   ;
                            o_timer_sec_clk = 1'b0       ;
                            o_timer_min_clk = 1'b0       ;
                            o_timer_hour_clk= ~sw2       ;
                        end
                    endcase
                end
            endcase
        end
    endcase
end
endmodule





///====================
///       minsec 
///====================

module minsec(  o_min,
                o_sec,
                o_hour,
                o_max_hit_min,
                o_max_hit_sec,
                o_timer_sec_hit,
                o_timer_min_hit,
                o_alarm,

                i_position,
                i_start_stop,
                i_alarm_min_clk,
                i_alarm_sec_clk,
                i_alarm_hour_clk,
                i_timer_sec_clk,
                i_timer_min_clk,
                i_timer_hour_clk,
                i_alarm_en,
                i_min_clk,
                i_sec_clk,
                i_hour_clk,
                i_hour_check,
                i_mode,
                rst_n,
                clk            );


parameter   MODE_CLOCK =    2'b00;
parameter   MODE_SETUP =    2'b01;
parameter   MODE_ALARM =    2'b10;
parameter   MODE_TIMER =    2'b11;
parameter   POS_SEC    =    2'b00;
parameter   POS_MIN    =    2'b01;
parameter   POS_HOUR   =    2'b10;

parameter   STOP        =   1'b0;
parameter   START       =   1'b1;

output  [5:0]   o_min               ;
output  [5:0]   o_sec               ;
output  [5:0]   o_hour              ;
output          o_max_hit_min       ;
output          o_max_hit_sec       ;
output          o_timer_sec_hit     ;
output          o_timer_min_hit     ;
output          o_alarm             ;

input   [5:0]   i_hour_check        ;
input   [1:0]   i_position          ;
input           i_alarm_en          ;
input			i_start_stop		;
input           i_sec_clk           ;
input           i_min_clk           ;
input           i_hour_clk          ;
input           i_alarm_sec_clk     ;
input           i_alarm_min_clk     ;
input			i_alarm_hour_clk	;
input           i_timer_sec_clk     ;
input           i_timer_min_clk     ;
input			i_timer_hour_clk	;
input           rst_n               ;
input           clk                 ;
input   [1:0]   i_mode              ;

// Mode clock
wire    [5:0]   sec                 ;
hms_cnt_up u0_hms_cnt(  .o_hms_cnt  (sec            ),
                        .o_max_hit  (o_max_hit_sec  ),
                        .i_max_cnt  (6'd59          ),
                        .clk        (i_sec_clk      ),
                        .rst_n      (rst_n          )   );


wire    [5:0]   min                 ;
hms_cnt_up u1_hms_cnt(  .o_hms_cnt  (min            ),
                        .o_max_hit  (o_max_hit_min  ),
                        .i_max_cnt  (6'd59          ),
                        .clk        (i_min_clk      ),
                        .rst_n      (rst_n          )   );

wire    [5:0]   hour                 ;
hms_cnt_up u2_hms_cnt(  .o_hms_cnt  (hour           ),
                        .o_max_hit  (               ),
                        .i_max_cnt  (6'd23          ),
                        .clk        (i_hour_clk     ),
                        .rst_n      (rst_n          )   );



//Mode Alarm
wire    [5:0]   alarm_sec                 ;
hms_cnt_up u3_hms_cnt(  .o_hms_cnt  (alarm_sec          ),
                        .o_max_hit  (                   ),
                        .i_max_cnt  (6'd59              ),
                        .clk        (i_alarm_sec_clk    ),
                        .rst_n      (rst_n              )   );


wire    [5:0]   alarm_min                 ;
hms_cnt_up u4_hms_cnt(  .o_hms_cnt  (alarm_min          ),
                        .o_max_hit  (                   ),
                        .i_max_cnt  (6'd59              ),
                        .clk        (i_alarm_min_clk    ),
                        .rst_n      (rst_n              )   );

wire    [5:0]   alarm_hour                 ;
hms_cnt_up u5_hms_cnt(  .o_hms_cnt  (alarm_hour         ),
                        .o_max_hit  (                   ),
                        .i_max_cnt  (6'd23              ),
                        .clk        (i_alarm_hour_clk   ),
                        .rst_n      (rst_n              )   );




//MODE TIMER
wire    [5:0]   timer_sec;
updw_hms u6 (   .o_hms_cnt          (timer_sec          ),
                .o_max_or_min_hit   (o_timer_sec_hit    ),
                .i_option           (i_start_stop       ),
                .i_max_cnt          (6'd59              ),
                .i_min_cnt          (6'd0               ),
                .clk                (i_timer_sec_clk    ),
                .clk_50MHz          (clk                ),
                .rst_n              (rst_n              )       );

        
wire    [5:0]   timer_min;
updw_hms u7 (   .o_hms_cnt          (timer_min          ),
                .o_max_or_min_hit   (o_timer_min_hit    ),
                .i_option           (i_start_stop       ),
                .i_max_cnt          (6'd59              ),
                .i_min_cnt          (6'd0               ),
                .clk                (i_timer_min_clk    ),
                .clk_50MHz          (clk                ),
                .rst_n              (rst_n              )       );


wire    [5:0]   timer_hour;
updw_hms u8 (   .o_hms_cnt          (timer_hour         ),
                .o_max_or_min_hit   (                   ),
                .i_option           (i_start_stop       ),
                .i_max_cnt          (6'd59              ),
                .i_min_cnt          (6'd0               ),
                .clk                (i_timer_hour_clk   ),
                .clk_50MHz          (clk                ),
                .rst_n              (rst_n              )       );




//MUX
reg     [5:0]   o_sec   ;
reg     [5:0]   o_min   ;
reg     [5:0]   o_hour  ;

always @(*) begin
    case(i_mode)
        MODE_CLOCK: begin
            o_sec   =   sec     ;
            o_min   =   min     ;
            o_hour  =   hour    ;
        end
        MODE_SETUP: begin
            o_sec   =   sec     ;
            o_min   =   min     ;
            o_hour  =   hour    ;
        end
        MODE_ALARM: begin
            o_sec   =   alarm_sec   ;  
            o_min   =   alarm_min   ;
            o_hour  =   alarm_hour  ;
        end
        MODE_TIMER: begin
            o_sec   =   timer_sec   ;  
            o_min   =   timer_min   ;
            o_hour  =   timer_hour  ;
        end
    endcase
end



//Alarm with auto stopping in 5 seconds in MODE_ALARM 
wire    clk_1hz ;

nco u1_nco( .o_clk  (clk_1hz        ),
            .i_num  (50000000       ),
            .i_clk  (clk            ),
            .i_rstn (rst_n          )   );



reg [3:0]   alarm_cnt;
always @(posedge clk_1hz or negedge rst_n) begin
    if (rst_n == 1'b0) begin
        alarm_cnt = 0;
    end else begin  
        if (o_alarm == 1'b1) begin
            alarm_cnt = alarm_cnt + 1;
        end else begin
            alarm_cnt = 0;
        end
    end
end

reg     o_alarm     ;
always @(posedge clk or negedge rst_n) begin
    if (rst_n == 1'b0 ) begin
        o_alarm <= 1'b0;
    end else begin
        if( (sec == alarm_sec )&& (min==alarm_min) &&(hour==alarm_hour)) begin
            o_alarm <= 1'b1 & i_alarm_en;
        end else begin
            if( (timer_sec == 6'd0 ) && (timer_min == 6'd0) && (timer_hour == 6'd0)) begin
                o_alarm <= 1'b1 & i_alarm_en;
            end else begin
                if(alarm_cnt >= 5) begin
                    o_alarm <= 1'b0;
                end
            end
        end
    end
end
endmodule


///==============================
///  top_hms_clock :: TopModule
///==============================

module  top_hms_clock_alarm   ( o_seg,
                                o_seg_dp,
                                o_seg_enb,
                                o_alarm,

                                clk,
                                i_ir_rxb,
                                rst_n         );



output  [6:0]   o_seg           ;
output  [5:0]   o_seg_enb       ;
output          o_seg_dp        ;
output          o_alarm         ;
input           clk             ;
input           rst_n           ;
input           i_ir_rxb		;

wire    [1:0]   position_node   ;
wire    [1:0]   mode_node       ;
wire            alarm           ;


wire    [31:0]  data_node;
wire            signal_separ_node;

ir_rx   u_ir_rx(    .o_data             (data_node          ),
                    .one_signal_separ   (signal_separ_node  ),
                    .i_ir_rxb           (i_ir_rxb           ),
                    .clk                (clk                ),
                    .rst_n              (rst_n              )       );



wire            sw0_node;
wire            sw1_node;
wire            sw2_node;
wire            sw3_node;

remote_signal_into_i_sw u_remote (      .o_sw0              (sw0_node           ),
                                        .o_sw1              (sw1_node           ),
                                        .o_sw2              (sw2_node           ),
                                        .o_sw3              (sw3_node           ),
                                        .clk                (clk                ),
                                        .i_data             (data_node          ),
                                        .one_signal_separ   (signal_separ_node  )   );



wire            startstop_node      ;
wire            timerhitnode_sec    ;
wire            timerhitnode_min    ;
wire            maxhitnode_min      ;
wire            maxhitnode_sec      ;
wire            node_min_clk        ;
wire            node_sec_clk        ;
wire            node_hour_clk       ;
wire            alarm_en_node       ;
wire            alarm_min_node      ;
wire            alarm_sec_node      ;
wire            alarm_hour_node     ;
wire            timer_min_node      ;
wire            timer_sec_node      ;
wire            timer_hour_node     ;

Controller  u_ctrl( .clk            (clk                ),
                    .rst_n          (rst_n              ),
                    .i_max_hit_min  (maxhitnode_min     ),
                    .i_max_hit_sec  (maxhitnode_sec     ),
                    .i_timer_sec_hit(timerhitnode_sec   ),
                    .i_timer_min_hit(timerhitnode_min   ),
                    .i_sw0           (sw0_node          ),
                    .i_sw1           (sw1_node          ),
                    .i_sw2           (sw2_node          ),
                    .i_sw3           (sw3_node          ),
                    .i_sec           (node_sec          ),
                    .i_min           (node_min          ),
                    .i_hour          (node_hour         ),
                    .o_alarm_en      (alarm_en_node     ),
                    .o_alarm_min_clk (alarm_min_node    ),
                    .o_alarm_sec_clk (alarm_sec_node    ),
                    .o_alarm_hour_clk(alarm_hour_node   ),
                    .o_timer_min_clk (timer_min_node    ),
                    .o_timer_sec_clk (timer_sec_node    ),
                    .o_timer_hour_clk(timer_hour_node   ),
                    .o_mode          (mode_node         ),
                    .o_min_clk       (node_min_clk      ),
                    .o_sec_clk       (node_sec_clk      ),
                    .o_hour_clk      (node_hour_clk     ),       
                    .o_position      (position_node     ),
                    .o_start_stop    (startstop_node    )       );





wire    [5:0]   node_sec        ;
wire    [5:0]   node_min        ;
wire    [5:0]   node_hour       ;

minsec      u_minsec(   .clk                (clk                ),
                        .i_min_clk          (node_min_clk       ),
                        .i_sec_clk          (node_sec_clk       ),
                        .i_hour_clk         (node_hour_clk      ),
                        .i_alarm_en         (alarm_en_node      ),
                        .i_alarm_min_clk    (alarm_min_node     ),
                        .i_alarm_sec_clk    (alarm_sec_node     ),
                        .i_alarm_hour_clk   (alarm_hour_node    ),
                        .i_timer_sec_clk    (timer_sec_node     ),
                        .i_timer_min_clk    (timer_min_node     ),
                        .i_timer_hour_clk   (timer_hour_node    ),
                        .i_mode             (mode_node          ),
                        .i_position         (position_node      ),
                        .i_start_stop       (startstop_node     ),
                        .rst_n              (rst_n              ),

                        .o_max_hit_min      (maxhitnode_min     ),
                        .o_max_hit_sec      (maxhitnode_sec     ),
                        .o_timer_sec_hit    (timerhitnode_sec   ),
                        .o_timer_min_hit    (timerhitnode_min   ),
                        .o_min              (node_min           ),
                        .o_sec              (node_sec           ),
                        .o_hour             (node_hour          ),
                        .o_alarm            (alarm              )   );






wire    [3:0]   sec_left           ;
wire    [3:0]   sec_right          ;
wire    [3:0]   min_left           ;
wire    [3:0]   min_right          ;
wire    [3:0]   hour_left          ;
wire    [3:0]   hour_right         ;

double_fig_sep  u0_dfs( .i_double_fig   (node_sec   ),
                        .o_left         (sec_left   ),
                        .o_right        (sec_right  )   );
double_fig_sep  u1_dfs( .i_double_fig   (node_min   ),
                        .o_left         (min_left   ),
                        .o_right        (min_right  )   );
double_fig_sep  u2_dfs( .i_double_fig   (node_hour   ),
                        .o_left         (hour_left   ),
                        .o_right        (hour_right  )   );






wire    [6:0]   seg_sec_left           ;
wire    [6:0]   seg_sec_right          ;
wire    [6:0]   seg_min_left           ;
wire    [6:0]   seg_min_right          ;
wire    [6:0]   seg_hour_left          ;
wire    [6:0]   seg_hour_right         ;

fnd_dec u0_fnd_dec( .i_num(sec_left     ),
                    .o_seg(seg_sec_left )   );

fnd_dec u1_fnd_dec( .i_num(sec_right    ),
                    .o_seg(seg_sec_right )   );

fnd_dec u2_fnd_dec( .i_num(min_left     ),
                    .o_seg(seg_min_left )   );

fnd_dec u3_fnd_dec( .i_num(min_right     ),
                    .o_seg(seg_min_right )   );

fnd_dec u4_fnd_dec( .i_num(hour_left     ),
                    .o_seg(seg_hour_left )   );

fnd_dec u5_fnd_dec( .i_num(hour_right     ),
                    .o_seg(seg_hour_right )   );




wire    [6:0]   blink_seg0;
wire    [6:0]   blink_seg1;
wire    [6:0]   blink_seg2;
wire    [6:0]   blink_seg3;
wire    [6:0]   blink_seg4;
wire    [6:0]   blink_seg5;

blink   u_blink (   .i_node0        (seg_sec_left       ),
                    .i_node1        (seg_sec_right      ),
                    .i_node2        (seg_min_left       ),
                    .i_node3        (seg_min_right      ),
                    .i_node4        (seg_hour_left      ),
                    .i_node5        (seg_hour_right     ),
                    .i_position     (position_node      ),
                    .i_mode         (mode_node          ),
                    .i_start_stop   (startstop_node     ),
                    .clk            (clk                ),
                    .rst_n          (rst_n              ),
                    
                    .o_seg0         (blink_seg0         ),
                    .o_seg1         (blink_seg1         ),
                    .o_seg2         (blink_seg2         ),
                    .o_seg3         (blink_seg3         ),
                    .o_seg4         (blink_seg4         ),
                    .o_seg5         (blink_seg5         )   );





wire    [41:0]  six_digit_seg          ;

assign          six_digit_seg = { blink_seg4, blink_seg5, blink_seg2, blink_seg3, blink_seg0, blink_seg1 };

led_disp    u_led_disp( .clk                (clk            ),
                        .i_six_digit_seg    (six_digit_seg  ),
                        .i_six_dp           (mode_node      ),
                        .rst_n              (rst_n          ),
                        .o_seg              (o_seg          ),
                        .o_seg_dp           (o_seg_dp       ),
                        .o_seg_enb          (o_seg_enb      )   );



buzz    u_buzz( .clk        (clk    ),
                .i_buzz_en  (alarm  ),
                .rst_n      (rst_n  ),
                .o_buzz     (o_alarm )   );

endmodule

