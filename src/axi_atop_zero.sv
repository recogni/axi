
// A connector that zeros out aw_atop
module axi_atop_zero #(
    parameter type  slv_req_t = logic, // request type slave port
    parameter type slv_resp_t = logic, // response type slave port
    parameter type  mst_req_t = logic, // request type master port
    parameter type mst_resp_t = logic  // response type master port
  ) (
    // slave port
    input  slv_req_t  slv_req_i,
    output slv_resp_t slv_resp_o,

    // master port
    output mst_req_t  mst_req_o,
    input  mst_resp_t mst_resp_i
  );
  
    assign mst_req_o = '{
      aw: '{
        id:     slv_req_i.aw.id,
        addr:   slv_req_i.aw.addr,
        len:    slv_req_i.aw.len,
        size:   slv_req_i.aw.size,
        burst:  slv_req_i.aw.burst,
        lock:   slv_req_i.aw.lock,
        cache:  slv_req_i.aw.cache,
        prot:   slv_req_i.aw.prot,
        qos:    slv_req_i.aw.qos,
        region: slv_req_i.aw.region,
        atop:   '0,
        user:   slv_req_i.aw.user
      },
      aw_valid: slv_req_i.aw_valid,
      w:        slv_req_i.w,
      w_valid:  slv_req_i.w_valid,
      b_ready:  slv_req_i.b_ready,
      ar: '{
        id:     slv_req_i.ar.id,
        addr:   slv_req_i.ar.addr,
        len:    slv_req_i.ar.len,
        size:   slv_req_i.ar.size,
        burst:  slv_req_i.ar.burst,
        lock:   slv_req_i.ar.lock,
        cache:  slv_req_i.ar.cache,
        prot:   slv_req_i.ar.prot,
        qos:    slv_req_i.ar.qos,
        region: slv_req_i.ar.region,
        user:   slv_req_i.ar.user
      },
      ar_valid: slv_req_i.ar_valid,
      r_ready:  slv_req_i.r_ready
    };
  
    assign slv_resp_o = mst_resp_i;
endmodule
  
`include "axi/typedef.svh"
`include "axi/assign.svh"
  
// interface wrapper
module axi_atop_zero_intf (
  AXI_BUS.Slave   in,
  AXI_BUS.Master  out
);

  localparam int unsigned ID_WIDTH   = $bits(in.aw_id);
  localparam int unsigned DATA_WIDTH = $bits(in.w_data);
  localparam int unsigned USER_WIDTH = $bits(in.aw_user);
  localparam int unsigned ADDR_WIDTH = $bits(in.aw_addr);

  typedef logic [ID_WIDTH-1:0]       id_t;
  typedef logic [ADDR_WIDTH-1:0]     addr_t;
  typedef logic [DATA_WIDTH-1:0]     data_t;
  typedef logic [DATA_WIDTH/8-1:0]   strb_t;
  typedef logic [USER_WIDTH-1:0]     user_t;

  `AXI_TYPEDEF_AW_CHAN_T(aw_chan_t, addr_t, id_t, user_t)
  `AXI_TYPEDEF_W_CHAN_T(w_chan_t, data_t, strb_t, user_t)
  `AXI_TYPEDEF_B_CHAN_T(b_chan_t, id_t, user_t)
  `AXI_TYPEDEF_AR_CHAN_T(ar_chan_t, addr_t, id_t, user_t)
  `AXI_TYPEDEF_R_CHAN_T(r_chan_t, data_t, id_t, user_t)
  `AXI_TYPEDEF_REQ_T(req_t, aw_chan_t, w_chan_t, ar_chan_t)
  `AXI_TYPEDEF_RESP_T(resp_t, b_chan_t, r_chan_t)

  req_t  slv_req,  mst_req;
  resp_t slv_resp, mst_resp;

  `AXI_ASSIGN_TO_REQ(slv_req, in)
  `AXI_ASSIGN_FROM_RESP(in, slv_resp)

  `AXI_ASSIGN_FROM_REQ(out, mst_req)
  `AXI_ASSIGN_TO_RESP(mst_resp, out)

  axi_atop_zero #(
    .slv_req_t  ( req_t      ), // request type slave port
    .slv_resp_t ( resp_t     ), // response type slave port
    .mst_req_t  ( req_t      ), // request type master port
    .mst_resp_t ( resp_t     )  // response type master port
  ) i_axi_atop_zero (
    // slave port
    .slv_req_i     ( slv_req     ),
    .slv_resp_o    ( slv_resp    ),
    // master port
    .mst_req_o     ( mst_req     ),
    .mst_resp_i    ( mst_resp    )
  );

endmodule
