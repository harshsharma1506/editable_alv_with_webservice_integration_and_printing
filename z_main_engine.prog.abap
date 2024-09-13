report z_main_engine
tables: mara, plaf, mapl.

include z_sel_screen.
include z_p_pp_cls.
include z_p_pp_forms.

*-----> at selection screen validate authorization

at selection-screen.
  call method lcl_mcs_report=>validate_auth.

*-----> at selection screen validate material and plant deletion too.

at selection-screen on s_matnr.
  call method lcl_mcs_report=>validate_material.
  call method lcl_mcs_report=>val_mat_del_werks.

start-of-selection.
  call method lcl_mcs_report=>get_data.      "fetch first data
  call method lcl_mcs_report=>build_layout.  "build layout
  call method lcl_mcs_report=>build_catalog. "build catalog
  if lv_flag_matnr <> 'X'.
    call method lcl_mcs_report=>call_alv.    "call ALV
  endif.
