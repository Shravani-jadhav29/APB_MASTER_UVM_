module apb(
    input logic clk, rst,
    input logic start, rw,
    input logic [3:0] addr, data,
    input logic pready, pslverr,
    input logic [3:0] prdata,

    output logic psel, penable, pwrite,
    output logic [3:0] paddr, pwdata,
    output logic [3:0] read_data,
    output logic done, error
);

    logic [1:0] state, next_state;

    parameter idle   = 2'b00;
    parameter setup  = 2'b01;
    parameter access = 2'b11;

    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= idle;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;

        case (state)
            idle:   
             if (start) 
               next_state = setup;
            setup:  
                 next_state = access;
            access: 
                if (pready) 
                  next_state = idle;

            default: next_state = idle;
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            psel <= 0;
            penable <= 0;
            pwrite <= 0;
            paddr <= 0;
            pwdata <= 0;
            read_data <= 0;
            done <= 0;
            error <= 0;
        end else begin
            done <= 0;
            error <= 0;

            case (state)
                idle: begin
                    psel <= 0;
                    penable <= 0;

                    if (start) begin
                        paddr <= addr;
                        pwdata <= data;
                        pwrite <= rw;
                        psel <= 1;
                    end
                end

                setup: begin
                    psel <= 1;
                    penable <= 0;
                end

                access: begin
                    psel <= 1;
                    penable <= 1;

                    if (pready) begin
                        if (!pwrite && !pslverr)
                            read_data <= prdata;

                        done <= 1;
                        error <= pslverr;
                        psel <= 0;
                        penable <= 0;
                    end
                end

                default: begin
                    psel <= 0;
                    penable <= 0;
                end
            endcase
        end
    end

endmodule
