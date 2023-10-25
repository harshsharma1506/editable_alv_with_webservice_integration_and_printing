include z_sel_screen.

selection-screen: begin of block b1 with frame title text-001.
parameters: p_werks type werks_d obligatory.   "plant
select-options: s_matnr for mara-matnr obligatory, "material number
                s_plnum for plaf-plnum,            "planned order number
                s_psttr for plaf-psttr,
                s_pedtr for plaf-pedtr,
                s_dispo for plaf-dispo.
selection-screen: end of block b1.

selection-screen: begin of block b2 with frame title text-003.
  parameters: p_print type char4 default '999'.
selection-screen: end of block b2.
