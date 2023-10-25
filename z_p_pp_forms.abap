include z_p_pp_forms.

   type-pools: slis.

   types: begin of ty_check,
          index type sy-tabix,
          end of ty_check.

   types: begin of ty_outbound,
           status type string,
           plan_dat_edit type dats,
           plnum type plnum,
           matnr type matnr,
           comp_mat type matnr,
           comp_desc type makt-maktx,
           qty_needed type emeng,
           mrp_contr type dispo,
           oprtn type vornr,
           long_text type string,
           wrk_cntr type arbpl,
           ltxa1  type ltxa1,
           end of ty_outbound.

   data: line_fieldcat1 type slis_fieldcat_alv.
   data: i_layout1   type slis_layout_alv.
   data: i_fieldcat1 type slis_t_fieldcat_alv.

   data: lt_outbound type standard table of ty_outbound,
         ls_outbound type ty_outbound.

   data:  lt_check type table of ty_check,
          ls_check type ty_check,
          lt_stb type standard table of  stpox,
          ls_stb type stpox,
          lt_matcat type standard table of cscmat,
          ls_matcat type cscmat,
          lv_plnnr type plnnr,
          lv_index type sy-tabix,
          lv_processed_flag type char1,
          lt_tsk type standard table of capp_tsk,
          lt_seq type standard table of capp_seq,
          lt_opr type standard table of capp_opr,
          ls_opr type capp_opr,
          lt_phase type standard table of capp_opr,
          lt_subtype type standard table of capp_opr,
          lt_rel type standard table of capp_rel,
          lt_com type standard table of capp_com,
          lt_reff type standard table of capp_opr,
          lt_refmis type standard table of capp_opr,
          lt_aenr type standard table of aenr,
          gs_top type cstmat,
          lt_mast type standard table of mast,
          lv_bom_del type char1 value ' ',
          lv_plnal type plnal,
          lv_delkz type delkz,
          lv_vornr type vornr,
          lv_arbpl type arbpl,
          lv_lines_matcat type i,
          lv_ltxa1 type ltxa1,
          lv_txtkz type txtkz,
          final_string_outbound type string,
          lv_name_txt type tdobname,
          lv_name_txt_temp type tdobname,
          lt_text_long type standard table of  tline,
          ls_text_long type tline,
          lv_zaehl type cim_count,
          lv_plnkn type plnkn,
          lv_comp_qty type emeng,
          lv_base_qty type emeng,
          g_container_tags type string,
          g_wa_input_lbl       type wsprint_by_user_soap_in,
          g_wa_input1_lbl      type wsset_printer_number_by_user_1,
          g_wa_output_lbl      type wsprint_by_user_soap_out,
          g_wa_output1_lbl     type wsset_printer_number_by_user_s,
          g_wa_output_trvltag type wsprint_by_user_soap_out,
          g_wa_output1_mat     type wsset_printer_number_by_user_s,
          lo_print_by_user type ref to co_wsprint_interface_soap,
          l_exception      type ref to cx_root,
          l_exception_mat type ref to cx_root,
          lv_msg type string,
          g_print type char4,
          lv_text_long_temp type char70.

   constants: c_date type char7 value 'DATE~',
              c_plnum type char12 value '||JOB~',
              c_matnr type char20 value '||PARENTSKU~',
              c_comp_mat type char30 value '||COMPONENTNO~',
              c_comp_desc type char30 value '||COMPONENTNAME~',
              c_qty type char30 value '||QTYNEEDED~',
              c_mrp_contr type char18 value '||MRP~',
              c_oprtn type char30 value '||OPERATIONNO~',
              c_long_txt type char16 value '||LONGTEXT~',
              c_wrk_cntr type char16  value '||APRINT~',
              c_ltxa1 type char25 value '||LABEL~'.

*&---------------------------------------------------------------------*
*&      Form  user_command
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->UCOMM      text
*      -->SELFIELD   text
*----------------------------------------------------------------------*
   form user_command using ucomm type sy-ucomm
                       selfield type slis_selfield.


*-----> routing to MD12 T code for Planned Order

     if selfield-fieldname = 'PLNUM'.
       case ucomm.
         when '&IC1'.
           set parameter id 'PAF'  field selfield-value.
           call transaction 'MD12' and skip first screen.
       endcase.
     endif.

*-----> validation of ALV screen inputs

     case ucomm.
       when '&DATA_SAVE'.
         clear g_wa_final.
         loop at g_it_final into g_wa_final.
           if g_wa_final-plan_check is not initial.
             ls_check-index = sy-tabix.
             append ls_check to lt_check.
             if g_wa_final-plan_check is initial and g_wa_final-plan_dat_edit is not initial.
               message 'Please Check the Line' type 'I' display like 'E'.
             elseif g_wa_final-plan_check is not initial and g_wa_final-plan_dat_edit is initial.
               message 'Please Fill the Date' type 'I' display like 'E'.
             endif.
           endif.
         endloop.
         if lines( lt_check ) > 1.
           message 'Please select only 1 line' type 'I' display like 'E'.
         endif.

*-----> FM Call ( BOM explode )

         clear g_wa_final.
         read table g_it_final into g_wa_final with key plan_check = 'X'.
         if sy-subrc = 0.

           if g_wa_final-plan_check = 'X' and g_wa_final-plan_dat_edit is not initial.
             "check the BOM deletion first
             select * from mast into table lt_mast where matnr = g_wa_final-matnr.
             if sy-subrc <> 0.
               message: 'BOM has been deleted' type 'I' display like 'E'.
               lv_bom_del = 'X'.
             endif.
             if lv_bom_del = ' '.
               call function 'CS_BOM_EXPL_MAT_V2'
                 exporting
                   capid                 = 'PP01'
                   datuv                 = sy-datum
                   emeng                 = g_wa_final-gsmng
                   mktls                 = 'X'
                   mehrs                 = 'X'
                   mtnrv                 = g_wa_final-matnr
                   svwvo                 = 'X'
                   werks                 = g_wa_final-pwwrk
                   vrsvo                 = 'X'
                   stlal                 = '1'
                 importing
                   topmat                = gs_top
                 tables
                   stb                   = lt_stb
                   matcat                = lt_matcat
                 exceptions
                   alt_not_found         = 1
                   call_invalid          = 2
                   material_not_found    = 3
                   missing_authorization = 4
                   no_bom_found          = 5
                   no_plant_data         = 6
                   no_suitable_bom_found = 7
                   conversion_error      = 8
                   others                = 9.
               if sy-subrc <> 0.
               else.
                 select single plnnr plnal into (lv_plnnr , lv_plnal) from mapl
                   where matnr = g_wa_final-matnr and werks = g_wa_final-pwwrk and plnty = 'N'.
                 if sy-subrc = 0.
                   select single delkz from plko into lv_delkz where plnnr = lv_plnnr and plnal = lv_plnal.
                   if lv_delkz is not initial.
                     message: ' Routing has been deleted' type 'I' display like 'E'.
                   endif.
                   call function 'CARO_ROUTING_READ'
                     exporting
                       date_from            = sy-datum
                       date_to              = '99991231'
                       plnty                = 'N'
                       plnnr                = lv_plnnr
                       plnal                = lv_plnal
                       matnr                = g_wa_final-matnr
                       buffer_del_flg       = 'X'
                       delete_all_cal_flg   = 'X'
                       adapt_flg            = 'X'
                       iv_create_add_change = ' '
                     tables
                       tsk_tab              = lt_tsk
                       seq_tab              = lt_seq
                       opr_tab              = lt_opr
                       phase_tab            = lt_phase
                       subopr_tab           = lt_subtype
                       rel_tab              = lt_rel
                       com_tab              = lt_com
                       referr_tab           = lt_reff
                       refmis_tab           = lt_refmis
                       it_aenr              = lt_aenr
                     exceptions
                       not_found            = 1
                       ref_not_exp          = 2
                       not_valid            = 3
                       others               = 4.
                   if sy-subrc <> 0.
                   endif.
                 else.
                   message: 'task group not found' type 'I' display like 'E'.
                 endif.
               endif.
             endif.
             perform outbound_processing.
*             perform popup_alv_status.
           endif.
         endif.
     endcase.

   endform.                    "user_command
*&---------------------------------------------------------------------*
*&      Form  OUTBOUND_PROCESSING
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
   form outbound_processing .

     data: lv_qty_c type c length 10.

     clear: g_wa_output_trvltag , g_wa_input_lbl ,  g_wa_input1_lbl ,  g_wa_output1_mat.
     create object lo_print_by_user.

     ls_outbound-plan_dat_edit = g_wa_final-plan_dat_edit.
     ls_outbound-plnum = g_wa_final-plnum.
     ls_outbound-matnr = g_wa_final-matnr.
     ls_outbound-mrp_contr = g_wa_final-dispo.

     select single vornr from afvc into lv_vornr where plnnr = lv_plnnr and plnal = lv_plnal.
     if sy-subrc = 0.
       ls_outbound-oprtn = lv_vornr.
     endif.

     lv_lines_matcat = lines( lt_matcat ).
     if lv_lines_matcat = 2.
       read table lt_matcat into ls_matcat index 2.
       ls_outbound-comp_mat = ls_matcat-matnr.
       select single maktx from makt into ls_outbound-comp_desc
         where matnr = ls_outbound-comp_mat and spras = 'EN'.
     else.
       ls_outbound-comp_mat = 'BLANK'.
       ls_outbound-comp_desc = 'BLANK'.
     endif.

     read table lt_opr into ls_opr with key plnnr = lv_plnnr.
     if sy-subrc = 0.
       select single arbpl into lv_arbpl from crhd where objid = ls_opr-arbid.
       if sy-subrc = 0.
         ls_outbound-wrk_cntr = lv_arbpl.
       endif.
     endif.

     loop at lt_stb into ls_stb.
       at end of mngko.
         sum.
         add ls_stb-mngko to lv_comp_qty.
       endat.
     endloop.

     select single bmeng from stko into lv_base_qty where stlnr = ls_stb-stlnr.

     ls_outbound-qty_needed = ( lv_comp_qty / lv_base_qty ) * g_wa_final-gsmng.

     select single ltxa1 from plpo into lv_ltxa1 where arbid = ls_opr-arbid and plnnr = lv_plnnr and plnty = 'N'.
     if sy-subrc = 0.
       ls_outbound-ltxa1 = lv_ltxa1.
     endif.

     select single txtkz from pbim into lv_txtkz where matnr = g_wa_final-matnr and werks = g_wa_final-pwwrk.

     if sy-subrc = 0.
       select single plnkn zaehl from plpo into (lv_plnkn, lv_zaehl) where plnnr = lv_plnnr and plnty = 'N'.
       if sy-subrc = 0.
         concatenate sy-mandt 'N' lv_plnnr lv_plnkn lv_zaehl into lv_name_txt_temp separated by '%'.
       endif.
       select single tdname from stxh into lv_name_txt where tdname like lv_name_txt_temp and tdid = 'PLPO' and tdobject = 'ROUTING'.
       if sy-subrc = 0.
         call function 'READ_TEXT'
           exporting
             client                        = sy-mandt
             id                            = 'PLPO'
             language                      = 'E'
             name                          = lv_name_txt
             object                        = 'ROUTING'
*            ARCHIVE_HANDLE                = 0
*            LOCAL_CAT                     = ' '
*          IMPORTING
*            HEADER                        =
*            OLD_LINE_COUNTER              =
           tables
             lines                         = lt_text_long
            exceptions
              id                            = 1
              language                      = 2
              name                          = 3
              not_found                     = 4
              object                        = 5
              reference_check               = 6
              wrong_access_to_archive       = 7
              others                        = 8.
         if sy-subrc <> 0.
* Implement suitable error handling here
         endif.
       endif.
     endif.

*     read table lt_text_long into ls_text_long index 1.
*     ls_outbound-long_text = ls_text_long-tdline.

     loop at lt_text_long into ls_text_long.
       lv_text_long_temp = ls_text_long-tdline.
       concatenate ls_outbound-long_text lv_text_long_temp into ls_outbound-long_text separated by ' '.
     endloop.
     condense ls_outbound-long_text.

     move ls_outbound-qty_needed to lv_qty_c.
     concatenate c_date ls_outbound-plan_dat_edit c_plnum ls_outbound-plnum c_matnr ls_outbound-matnr c_comp_mat ls_outbound-comp_mat c_comp_desc ls_outbound-comp_desc c_qty lv_qty_c
     c_mrp_contr ls_outbound-mrp_contr c_oprtn ls_outbound-oprtn c_long_txt ls_outbound-long_text c_wrk_cntr ls_outbound-wrk_cntr c_ltxa1 ls_outbound-ltxa1 into g_container_tags.

     try.

         g_wa_input1_lbl-printer_number = g_print.
         g_wa_input1_lbl-username       = sy-uname.

         lo_print_by_user->set_printer_number_by_user(
           exporting
              input =                           g_wa_input1_lbl
           importing
              output =                          g_wa_output1_lbl
         ).
       catch cx_ai_system_fault into l_exception.
         raise exception type cx_wd_no_handler
           exporting
             previous = l_exception.
       catch cx_ai_application_fault into l_exception.
         raise exception type cx_wd_no_handler
           exporting
             previous = l_exception.
       catch cx_root into l_exception.
     endtry.

     g_wa_input_lbl-business_process_name = 'TRAVELLERTAG'."(001).
     g_wa_input_lbl-username              = sy-uname.
     g_wa_input_lbl-label_values          = g_container_tags.
     g_wa_input_lbl-plant                 = '720'.
     g_wa_input_lbl-warehouse             = 'SED'.
     g_wa_input_lbl-label_count           = 1.

     try.
         lo_print_by_user->print_by_user(
           exporting
              input =  g_wa_input_lbl
           importing
              output = g_wa_output_trvltag ).

       catch cx_ai_system_fault into l_exception_mat.
         raise exception type cx_wd_no_handler
           exporting
             previous = l_exception_mat.
       catch cx_ai_application_fault into l_exception_mat.
         raise exception type cx_wd_no_handler
           exporting
             previous = l_exception_mat.
       catch cx_root into l_exception_mat.
         lv_msg = l_exception_mat->get_longtext( ).
         message lv_msg type 'E'.
     endtry.
     ls_outbound-status = g_wa_output_trvltag-status_message.
     append ls_outbound to lt_outbound.
     perform popup_alv_status.

   endform.                    " OUTBOUND_PROCESSING
*&---------------------------------------------------------------------*
*&      Form  POPUP_ALV_STATUS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
   form popup_alv_status .

     clear i_layout1.
     i_layout1-colwidth_optimize = 'X'.
     i_layout1-zebra = 'X'.

     clear line_fieldcat1.
     line_fieldcat1-fieldname = 'STATUS'.
     line_fieldcat1-tabname   = 'LT_OUTBOUND'.
     line_fieldcat1-seltext_m = 'Status of Print'.
     append line_fieldcat1 to i_fieldcat1.

     clear line_fieldcat1.
     line_fieldcat1-fieldname = 'PLAN_DAT_EDIT'.
     line_fieldcat1-tabname   = 'LT_OUTBOUND'.
     line_fieldcat1-seltext_m = 'Date'.
     append line_fieldcat1 to i_fieldcat1.

     clear line_fieldcat1.
     line_fieldcat1-fieldname = 'PLNUM'.
     line_fieldcat1-tabname   = 'LT_OUTBOUND'.
     line_fieldcat1-seltext_m = 'Planned Order'.
     append line_fieldcat1 to i_fieldcat1.

     clear line_fieldcat1.
     line_fieldcat1-fieldname = 'MATNR'.
     line_fieldcat1-tabname   = 'LT_OUTBOUND'.
     line_fieldcat1-seltext_m = 'Material'.
     append line_fieldcat1 to i_fieldcat1.

     clear line_fieldcat1.
     line_fieldcat1-fieldname = 'COMP_MAT'.
     line_fieldcat1-tabname   = 'LT_OUTBOUND'.
     line_fieldcat1-seltext_m = 'Component No.'.
     append line_fieldcat1 to i_fieldcat1.

     clear line_fieldcat1.
     line_fieldcat1-fieldname = 'COMP_DESC'.
     line_fieldcat1-tabname   = 'LT_OUTBOUND'.
     line_fieldcat1-seltext_m = 'Component Desc'.
     append line_fieldcat1 to i_fieldcat1.

     clear line_fieldcat1.
     line_fieldcat1-fieldname = 'QTY_NEEDED'.
     line_fieldcat1-tabname   = 'LT_OUTBOUND'.
     line_fieldcat1-seltext_m = 'Quantity'.
     append line_fieldcat1 to i_fieldcat1.

     clear line_fieldcat1.
     line_fieldcat1-fieldname = 'MRP_CONTR'.
     line_fieldcat1-tabname   = 'LT_OUTBOUND'.
     line_fieldcat1-seltext_m = 'MRP Controller'.
     append line_fieldcat1 to i_fieldcat1.

     clear line_fieldcat1.
     line_fieldcat1-fieldname = 'OPRTN'.
     line_fieldcat1-tabname   = 'LT_OUTBOUND'.
     line_fieldcat1-seltext_m = 'Operation No.'.
     append line_fieldcat1 to i_fieldcat1.

     clear line_fieldcat1.
     line_fieldcat1-fieldname = 'LONG_TEXT'.
     line_fieldcat1-tabname   = 'LT_OUTBOUND'.
     line_fieldcat1-seltext_m = 'Long Text'.
     append line_fieldcat1 to i_fieldcat1.

     clear line_fieldcat1.
     line_fieldcat1-fieldname = 'WRK_CNTR'.
     line_fieldcat1-tabname   = 'LT_OUTBOUND'.
     line_fieldcat1-seltext_m = 'Work Center'.
     append line_fieldcat1 to i_fieldcat1.

     clear line_fieldcat1.
     line_fieldcat1-fieldname = 'LTXA1'.
     line_fieldcat1-tabname   = 'LT_OUTBOUND'.
     line_fieldcat1-seltext_m = 'Operation Text'.
     append line_fieldcat1 to i_fieldcat1.

     call function 'REUSE_ALV_POPUP_TO_SELECT'
       exporting
         i_title                       = 'Things Processed'
         i_allow_no_selection          = 'X'
         i_zebra                       = 'X'
         i_tabname                     = 'LT_OUTBOUND'
*        I_STRUCTURE_NAME              =
         it_fieldcat                   = i_fieldcat1
*        IT_EXCLUDING                  =
*        I_CALLBACK_PROGRAM            =
*        I_CALLBACK_USER_COMMAND       =
*        IS_PRIVATE                    =
*      IMPORTING
*        ES_SELFIELD                   =
*        E_EXIT                        =
       tables
         t_outtab                      = lt_outbound
      EXCEPTIONS
        PROGRAM_ERROR                 = 1
        OTHERS                        = 2
               .
     if sy-subrc <> 0.
* Implement suitable error handling here
     endif.
   endform.                    " POPUP_ALV_STATUS
