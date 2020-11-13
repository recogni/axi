// Modify IDs on an AXI4 bus
//
// zero-cycle connector logic which simply replaces the axi_id fields with supplied values on each
// of aw, ar, b and r channels
module axi_modify_id #(
  parameter type slv_id_t = logic,    // id type on slave interface
  parameter type slv_req_t = logic,   // slv_req typedef
  parameter type slv_resp_t = logic,  // slv_resp typedef
  parameter type mst_id_t = logic,    // id type on master interface
  parameter type mst_req_t = logic,   // mst_req typedef
  parameter type mst_resp_t = logic   // mst_resp typedef
) (
  input  slv_req_t  slv_req_i,
  input  mst_id_t mst_aw_id_i,    // new aw_id to replace in mst_req_o
  input  mst_id_t mst_ar_id_i,    // new ar_id to replace in mst_req_o
  output mst_req_t  mst_req_o,

  input  mst_resp_t mst_resp_i,
  input  slv_id_t slv_b_id_i,    // new b_id to replace in slv_resp_o
  input  slv_id_t slv_r_id_i,    // new r_id to replace in slv_resp_o
  output slv_resp_t slv_resp_o
);

  assign mst_req_o = '{
    aw: '{
      id:     mst_aw_id_i,
      addr:   slv_req_i.aw.addr,
      len:    slv_req_i.aw.len,
      size:   slv_req_i.aw.size,
      burst:  slv_req_i.aw.burst,
      lock:   slv_req_i.aw.lock,
      cache:  slv_req_i.aw.cache,
      prot:   slv_req_i.aw.prot,
      qos:    slv_req_i.aw.qos,
      region: slv_req_i.aw.region,
      atop:   slv_req_i.aw.atop,
      user:   slv_req_i.aw.user,
      default: '0
    },
    aw_valid: slv_req_i.aw_valid,
    w:        slv_req_i.w,
    w_valid:  slv_req_i.w_valid,
    b_ready:  slv_req_i.b_ready,
    ar: '{
      id:     mst_ar_id_i,
      addr:   slv_req_i.ar.addr,
      len:    slv_req_i.ar.len,
      size:   slv_req_i.ar.size,
      burst:  slv_req_i.ar.burst,
      lock:   slv_req_i.ar.lock,
      cache:  slv_req_i.ar.cache,
      prot:   slv_req_i.ar.prot,
      qos:    slv_req_i.ar.qos,
      region: slv_req_i.ar.region,
      user:   slv_req_i.ar.user,
      default: '0
    },
    ar_valid: slv_req_i.ar_valid,
    r_ready:  slv_req_i.r_ready,
    default: '0
  };

  assign slv_resp_o = '{
    aw_ready: mst_resp_i.aw_ready,
    ar_ready: mst_resp_i.ar_ready,
    w_ready:  mst_resp_i.w_ready,

    b: '{
      id:     slv_b_id_i,
      resp:   mst_resp_i.b_resp,  
      user:   mst_resp_i.b_user,  
      default: '0
    },
    b_valid: mst_resp_i.b_valid,

    r: '{
      id:     slv_r_id_i,
      data:   mst_resp_i.r_data,  
      resp:   mst_resp_i.r_resp,  
      last:   mst_resp_i.r_last,  
      user:   mst_resp_i.r_user,  
      default: '0
    },
    r_valid:  mst_resp_i.r_valid,

    default: '0
  };
endmodule


`include "axi/typedef.svh"
`include "axi/assign.svh"

/// Interface variant of [`axi_modify_id`](module.axi_modify_id)
module axi_modify_id_intf #(
  /// ID width of slave port
  parameter int unsigned AXI_SLV_PORT_ID_WIDTH = 0,
  /// ID width of master port
  parameter int unsigned AXI_MST_PORT_ID_WIDTH = AXI_SLV_PORT_ID_WIDTH,
  /// Data width of slave and master port
  parameter int unsigned AXI_DATA_WIDTH = 0,
  /// Addr width of slave and master port
  parameter int unsigned AXI_ADDR_WIDTH = 0,
  /// User signal width of slave and master port
  parameter int unsigned AXI_USER_WIDTH = 0
) (
  /// B ID to replace on slave port; must remain stable while B handshake is pending.
  input  [AXI_SLV_PORT_ID_WIDTH-1:0] slv_b_id_i,
  /// R ID to replace on slave port; must remain stable while R handshake is pending.
  input  [AXI_SLV_PORT_ID_WIDTH-1:0] slv_r_id_i,
  /// Slave port
  AXI_BUS.Slave     slv,

  /// AW ID to replace on master port; must remain stable while an AW handshake is pending.
  input  [AXI_MST_PORT_ID_WIDTH-1:0] mst_aw_id_i,
  /// AR ID to replace on master port; must remain stable while an AR handshake is pending.
  input  [AXI_MST_PORT_ID_WIDTH-1:0] mst_ar_id_i,
  /// Master port
  AXI_BUS.Master    mst
);

  typedef logic [AXI_SLV_PORT_ID_WIDTH-1:0]   slv_id_t;
  typedef logic [AXI_MST_PORT_ID_WIDTH-1:0]   mst_id_t;
  typedef logic [AXI_ADDR_WIDTH-1:0]          addr_t;
  typedef logic [AXI_DATA_WIDTH-1:0]          data_t;
  typedef logic [AXI_DATA_WIDTH/8-1:0]        strb_t;
  typedef logic [AXI_USER_WIDTH-1:0]          user_t;

  `AXI_TYPEDEF_AW_CHAN_T(slv_aw_chan_t, addr_t, slv_id_t, user_t)
  `AXI_TYPEDEF_AW_CHAN_T(mst_aw_chan_t, addr_t, mst_id_t, user_t)
  `AXI_TYPEDEF_W_CHAN_T(w_chan_t, data_t, strb_t, user_t)
  `AXI_TYPEDEF_B_CHAN_T(slv_b_chan_t, slv_id_t, user_t)
  `AXI_TYPEDEF_B_CHAN_T(mst_b_chan_t, mst_id_t, user_t)
  `AXI_TYPEDEF_AR_CHAN_T(slv_ar_chan_t, addr_t, slv_id_t, user_t)
  `AXI_TYPEDEF_AR_CHAN_T(mst_ar_chan_t, addr_t, mst_id_t, user_t)
  `AXI_TYPEDEF_R_CHAN_T(slv_r_chan_t, data_t, slv_id_t, user_t)
  `AXI_TYPEDEF_R_CHAN_T(mst_r_chan_t, data_t, mst_id_t, user_t)
  `AXI_TYPEDEF_REQ_T(slv_req_t, slv_aw_chan_t, w_chan_t, slv_ar_chan_t)
  `AXI_TYPEDEF_REQ_T(mst_req_t, mst_aw_chan_t, w_chan_t, mst_ar_chan_t)
  `AXI_TYPEDEF_RESP_T(slv_resp_t, slv_b_chan_t, slv_r_chan_t)
  `AXI_TYPEDEF_RESP_T(mst_resp_t, mst_b_chan_t, mst_r_chan_t)

  slv_req_t  slv_req;
  mst_req_t  mst_req;
  slv_resp_t  slv_resp;
  mst_resp_t  mst_resp;

  `AXI_ASSIGN_TO_REQ(slv_req, slv)
  `AXI_ASSIGN_FROM_RESP(slv, slv_resp)

  `AXI_ASSIGN_FROM_REQ(mst, mst_req)
  `AXI_ASSIGN_TO_RESP(mst_resp, mst)

  axi_modify_id #(
    .slv_id_t   ( slv_id_t ),
    .slv_req_t  ( slv_req_t  ),
    .slv_resp_t ( slv_resp_t  ),
    .mst_id_t   ( mst_id_t ),
    .mst_req_t  ( mst_req_t  ),
    .mst_resp_t ( mst_resp_t  ),
  ) i_axi_modify_id (
    .slv_req_i     ( slv_req  ),
    .mst_aw_id_i   ( mst_aw_id_i),
    .mst_ar_id_i   ( mst_ar_id_i),
    .mst_req_o     ( mst_req  ),
    
    .mst_resp_i    ( mst_resp ),
    .slv_b_id_i    ( slv_b_id_i),
    .slv_r_id_i    ( slv_r_id_i),
    .slv_resp_o    ( slv_resp )
  );

// pragma translate_off
`ifndef VERILATOR
  initial begin
    assert(AXI_SLV_PORT_ID_WIDTH > 0);
    assert(AXI_MST_PORT_ID_WIDTH > 0);
    assert(AXI_DATA_WIDTH > 0);
    assert(AXI_ADDR_WIDTH > 0);
  end
`endif
// pragma translate_on
endmodule
