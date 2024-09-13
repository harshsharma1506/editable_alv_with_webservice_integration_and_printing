include z_p_pp_cls.

type-pools: slis.

types: begin of ty_mara,
       matnr type mara-matnr,
       mtart type mara-mtart,
       lvorm type mara-lvorm,
       end of ty_mara.

types: begin of ty_marc,
       matnr type marc-matnr,
       lvorm type marc-lvorm,
       end of ty_marc.

types: begin of ty_alv_structure,
       plan_check type c,
       plan_dat_edit type sy-datum,
       pwwrk type plaf-pwwrk,
       matnr type plaf-matnr,
       plnum type plaf-plnum,
       gsmng type plaf-gsmng,
       psttr type plaf-psttr,
       pedtr type plaf-pedtr,
       dispo type plaf-dispo,
       auffx type plaf-auffx,
       end of ty_alv_structure.

data: g_it_mara type standard table of ty_mara,
      g_wa_mara type ty_mara,
      g_it_final type standard table of ty_alv_structure,
      g_wa_final type ty_alv_structure,
      lv_flag_matnr type c,
      g_it_marc type standard table of ty_marc,
      g_wa_marc type ty_marc,
      lv_begru type begru.

data: i_layout   type slis_layout_alv.
data: i_fieldcat type slis_t_fieldcat_alv.

data: report_id  like sy-repid.
data: ws_title   type lvc_title value 'Planned Order List'.


*----------------------------------------------------------------------*
*       CLASS lcl_mcs_report DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
class lcl_mcs_report definition final.
  public section.
    class-data: lv_mtart.
    constants: c_fert type mtart value 'FERT'.
    class-methods:
    validate_auth,
    validate_material,
    val_mat_del_werks,
    get_data,
    build_catalog,
    build_layout,
    call_alv.
endclass.                    "lcl_mcs_report DEFINITION

*----------------------------------------------------------------------*
*       CLASS lcl_mcs_report IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
class lcl_mcs_report implementation.

  method validate_auth.

    select single begru from mara into lv_begru where matnr = s_matnr-low.

    authority-check object 'M_MATE_MAT'
    id 'BEGRU' field lv_begru
*    id 'MATNR' field s_matnr-high
    id 'ACTVT' field '03'.
    if sy-subrc <> 0.
      message 'no authorization' type 'I' display like 'E'.
    endif.

    authority-check object 'M_MATE_WRK'
    id 'WERKS' field p_werks
    id 'ACTVT' field '03'.
    if sy-subrc <> 0.
      message 'no authorization' type 'I' display like 'E'.
    endif.
  endmethod.                    "validate_auth

  method validate_material.
    if s_matnr is not initial.
      select matnr mtart from mara into corresponding fields of table g_it_mara where matnr in s_matnr.
      loop at g_it_mara into g_wa_mara.
        if g_wa_mara-mtart <> c_fert.
          lv_flag_matnr = 'X'.
          message: 'Entered Material is not FERT type' type 'I' display like 'E'.
        endif.
        if g_wa_mara-lvorm is not initial.
          message: 'Material Master at Client Level Deleted' type 'I' display like 'E'.
        endif.
      endloop.
    endif.
  endmethod.                    "validate_plant

  method val_mat_del_werks.
    if s_matnr is not initial.
      select * from marc into corresponding fields of table g_it_marc where matnr in s_matnr.
      if sy-subrc = 0.
        loop at g_it_marc into g_wa_marc.
          if g_wa_marc-lvorm is not initial.
            message: 'Material Master at Plant Level Deleted' type 'I' display like 'E'.
          endif.
        endloop.
      endif.
    endif.
  endmethod.                    "val_mat_del_werks

  method get_data.
    select pwwrk matnr plnum gsmng psttr pedtr dispo auffx from plaf into corresponding fields of table g_it_final
      where pwwrk = p_werks
      and   matnr in s_matnr
      and   plnum in s_plnum
      and   dispo in s_dispo
      and   pedtr in s_pedtr
      and   psttr in s_psttr.
    if sy-subrc = 0.
      sort g_it_final ascending by psttr.
    endif.
  endmethod.                    "get_data

  method build_catalog.
    data: line_fieldcat type slis_fieldcat_alv.

    clear line_fieldcat.
    line_fieldcat-fieldname = 'PLAN_CHECK'.
    line_fieldcat-tabname   = 'G_IT_FINAL'.
    line_fieldcat-key       = 'X'.
    line_fieldcat-seltext_m = 'Plan'.
    line_fieldcat-checkbox = 'X'.
    line_fieldcat-edit = 'X'.
    append line_fieldcat to i_fieldcat.

    clear line_fieldcat.
    line_fieldcat-fieldname = 'PLAN_DAT_EDIT'.
    line_fieldcat-tabname   = 'G_IT_FINAL'.
    line_fieldcat-key       = 'X'.
    line_fieldcat-seltext_m = 'Planned Date'.
    line_fieldcat-edit = 'X'.
    line_fieldcat-input = 'X'.
    line_fieldcat-ref_tabname = 'PLAF'.
    line_fieldcat-ref_fieldname = 'PALTR'.
    append line_fieldcat to i_fieldcat.

    clear line_fieldcat.
    line_fieldcat-fieldname = 'PWWRK'.
    line_fieldcat-tabname   = 'G_IT_FINAL'.
    line_fieldcat-seltext_m = 'Production Plant'.

    append line_fieldcat to i_fieldcat.

    clear line_fieldcat.
    line_fieldcat-fieldname = 'MATNR'.
    line_fieldcat-tabname   = 'G_IT_FINAL'.

    line_fieldcat-seltext_m = 'Material'.
    append line_fieldcat to i_fieldcat.

    clear line_fieldcat.
    line_fieldcat-fieldname = 'PLNUM'.
    line_fieldcat-tabname   = 'G_IT_FINAL'.
    line_fieldcat-hotspot   = 'X'.
    line_fieldcat-emphasize = 'X'.
    line_fieldcat-seltext_m = 'Planned Order Number'.
    append line_fieldcat to i_fieldcat.

    clear line_fieldcat.
    line_fieldcat-fieldname = 'GSMNG'.
    line_fieldcat-tabname   = 'G_IT_FINAL'.
    line_fieldcat-seltext_m = 'Total Quantity'.

    append line_fieldcat to i_fieldcat.

    clear line_fieldcat.
    line_fieldcat-fieldname = 'PSTTR'.
    line_fieldcat-tabname   = 'G_IT_FINAL'.
    line_fieldcat-seltext_m = 'Order Start Date'.

    append line_fieldcat to i_fieldcat.

    clear line_fieldcat.
    line_fieldcat-fieldname = 'PEDTR'.
    line_fieldcat-tabname   = 'G_IT_FINAL'.
    line_fieldcat-seltext_m = 'Order End Date'.

    append line_fieldcat to i_fieldcat.

    clear line_fieldcat.
    line_fieldcat-fieldname = 'DISPO'.
    line_fieldcat-tabname   = 'G_IT_FINAL'.
    line_fieldcat-seltext_m = 'MRP controller'.

    append line_fieldcat to i_fieldcat.

    clear line_fieldcat.
    line_fieldcat-fieldname = 'AUFFX'.
    line_fieldcat-tabname   = 'G_IT_FINAL'.
    line_fieldcat-seltext_m = 'Firming Ind'.

    append line_fieldcat to i_fieldcat.

  endmethod.                    "build_catalog

  method build_layout.
    clear i_layout.
    i_layout-colwidth_optimize = 'X'.
    i_layout-zebra = 'X'.
  endmethod.                    "build_layout

  method call_alv.
    call function 'REUSE_ALV_GRID_DISPLAY'
      exporting
        i_callback_program      = sy-repid
        i_callback_user_command = 'USER_COMMAND'
        i_grid_title            = ws_title
        is_layout               = i_layout
        it_fieldcat             = i_fieldcat
        i_save                  = 'A'
      tables
        t_outtab                = g_it_final
      exceptions
        program_error           = 1
        others                  = 2.
    if sy-subrc <> 0.
      message id sy-msgid type sy-msgty number sy-msgno
              with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    endif.
  endmethod.                    "call_alv


endclass.                    "lcl_mcs_report IMPLEMENTATION
