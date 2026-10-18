module csb_assertions (
    input wire        clk,
    input wire        resetn,

    input wire [31:0] in_data_o,
    input wire        in_valid_o,
    input wire        in_ready_i,

    input wire        out_pending,
    input wire        out_ready_o,

    input wire        command_submit,
    input wire        command_pop_out,
    input wire        error_status,

    input wire [2:0]  event_status,
    input wire        irq_o
);

default clocking cb @(posedge clk);
endclocking

default disable iff (!resetn);

// Input payload must remain stable while the receiver applies backpressure.
property p_input_stable_while_waiting;
    in_valid_o && !in_ready_i
    |=> in_valid_o && $stable(in_data_o);
endproperty

a_input_stable_while_waiting:
assert property (p_input_stable_while_waiting)
else $error("CSB ASSERT: input data/valid changed before READY");

// Output buffer full means the functional endpoint must see READY low.
a_output_pending_blocks_endpoint:
assert property (out_pending |-> !out_ready_o)
else $error("CSB ASSERT: out_ready_o high while output buffer is full");

// Output buffer empty means the endpoint may deliver a result.
a_output_empty_is_ready:
assert property (!out_pending |-> out_ready_o)
else $error("CSB ASSERT: out_ready_o low while output buffer is empty");

// IRQ is exactly the OR of all latched events.
a_irq_matches_event_status:
assert property (irq_o == (|event_status))
else $error("CSB ASSERT: irq_o does not match event_status");

// Illegal submit while an input word is already pending must become an error.
a_submit_while_pending_sets_error:
assert property (command_submit && in_valid_o |=> error_status)
else $error("CSB ASSERT: submit while pending did not set error");

// POP without a buffered result must become an error.
a_empty_pop_sets_error:
assert property (command_pop_out && !out_pending |=> error_status)
else $error("CSB ASSERT: empty POP did not set error");

// Useful assertion coverage: prove these cases actually occurred.
c_input_backpressure:
cover property (in_valid_o && !in_ready_i ##1 in_valid_o && in_ready_i);

c_submit_pending_error:
cover property (command_submit && in_valid_o ##1 error_status);

c_empty_pop_error:
cover property (command_pop_out && !out_pending ##1 error_status);

endmodule


// Bind assertions into every control_status_bridge_core instance.
// The referenced signal names are resolved inside the bound target scope.
bind control_status_bridge_core csb_assertions u_csb_assertions (
    .clk(clk),
    .resetn(resetn),

    .in_data_o(in_data_o),
    .in_valid_o(in_valid_o),
    .in_ready_i(in_ready_i),

    .out_pending(out_pending),
    .out_ready_o(out_ready_o),

    .command_submit(command_submit),
    .command_pop_out(command_pop_out),
    .error_status(error_status),

    .event_status(event_status),
    .irq_o(irq_o)
);
