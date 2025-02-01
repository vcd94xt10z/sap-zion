*
* Autor Vinicius Cesar Dias
* Projeto https://github.com/vcd94xt10z/sap-zion
* Versão 0.1
*
class ZCL_XLS_UTILS definition
  public
  final
  create public .

public section.

  class-methods CLASS_CONSTRUCTOR .
  class-methods ITAB_TO_XLS
    importing
      value(ITAB) type ANY TABLE
      value(XLS_FILE) type STRING
      value(SERVER) type FLAG optional .
  class-methods XLS_TO_ITAB
    importing
      !XLS_FILE type STRING
      value(SERVER) type FLAG optional
    exporting
      !ITAB type STANDARD TABLE .
protected section.
private section.
ENDCLASS.



CLASS ZCL_XLS_UTILS IMPLEMENTATION.


method CLASS_CONSTRUCTOR.
endmethod.


method ITAB_TO_XLS.
  DATA: ld_bin_filesize TYPE int4.
  DATA: lt_bintab       TYPE solix_tab.
  DATA: ld_xstring      TYPE xstring.
  DATA: lr_data_ref     TYPE REF TO data.

  FIELD-SYMBOLS: <ls_data> TYPE ANY TABLE.

  CLEAR ld_xstring.

  GET REFERENCE OF itab INTO lr_data_ref.
  ASSIGN lr_data_ref->* TO <ls_data>.

  cl_salv_table=>factory(
    IMPORTING
      r_salv_table = DATA(lo_table)
    CHANGING
      t_table      = <ls_data>
  ).

  DATA(lt_fcat) = cl_salv_controller_metadata=>get_lvc_fieldcatalog(
      r_columns      = lo_table->get_columns( )
      r_aggregations = lo_table->get_aggregations( )
  ).

  DATA(lo_result) = cl_salv_ex_util=>factory_result_data_table(
      r_data         = lr_data_ref
      t_fieldcatalog = lt_fcat
  ).

  cl_salv_bs_tt_util=>if_salv_bs_tt_util~transform(
    EXPORTING
      xml_type      = if_salv_bs_xml=>c_type_xlsx
      xml_version   = cl_salv_bs_a_xml_base=>get_version( )
      r_result_data = lo_result
      xml_flavour   = if_salv_bs_c_tt=>c_tt_xml_flavour_export
      gui_type      = if_salv_bs_xml=>c_gui_type_gui
    IMPORTING
      xml           = ld_xstring
  ).

  IF server = 'X'.
    " salvar no servidor
    OPEN DATASET xls_file FOR OUTPUT IN BINARY MODE.
    IF sy-subrc = 0.
      TRANSFER ld_xstring TO xls_file.
      CLOSE DATASET xls_file.
    ENDIF.
  ELSE.
    " salvar no PC do usuário
    CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
      EXPORTING
        buffer     = ld_xstring
      TABLES
        binary_tab = lt_bintab.

    ld_bin_filesize = xstrlen( ld_xstring ).

    cl_gui_frontend_services=>gui_download(
      EXPORTING
        filename                  = xls_file
        filetype                  = 'BIN'
        bin_filesize              = ld_bin_filesize
      CHANGING
        data_tab                  = lt_bintab
      EXCEPTIONS
        file_write_error          = 1
        no_batch                  = 2
        gui_refuse_filetransfer   = 3
        invalid_type              = 4
        no_authority              = 5
        unknown_error             = 6
        header_not_allowed        = 7
        separator_not_allowed     = 8
        filesize_not_allowed      = 9
        header_too_long           = 10
        dp_error_create           = 11
        dp_error_send             = 12
        dp_error_write            = 13
        unknown_dp_error          = 14
        access_denied             = 15
        dp_out_of_memory          = 16
        disk_full                 = 17
        dp_timeout                = 18
        file_not_found            = 19
        dataprovider_exception    = 20
        control_flush_error       = 21
        not_supported_by_gui      = 22
        error_no_gui              = 23
        others                    = 24
    ).
  ENDIF.
endmethod.


method XLS_TO_ITAB.
  DATA: lt_solix          TYPE w3mimetabtype.
  DATA: lo_excel          TYPE REF TO cl_fdt_xl_spreadsheet.
  DATA: ld_xstring        TYPE xstring.
  DATA: lt_worksheet_name TYPE if_fdt_doc_spreadsheet=>t_worksheet_names.
  DATA: ld_worksheet_name TYPE string.
  DATA: lo_worksheet_itab TYPE REF TO data.

  DATA: ld_valuef     TYPE f.
  DATA: ld_valuep(16) TYPE p DECIMALS 14.
  DATA: ld_valuedecf  TYPE decfloat34.

  FIELD-SYMBOLS: <ls_itab>       TYPE any.
  FIELD-SYMBOLS: <ld_value_to>   TYPE any.
  FIELD-SYMBOLS: <lt_worksheet>  TYPE STANDARD TABLE.
  FIELD-SYMBOLS: <ls_worksheet>  TYPE any.
  FIELD-SYMBOLS: <ld_value_from> TYPE any.

  IF server = 'X'.
    " lendo arquivo no servidor
    OPEN DATASET xls_file FOR INPUT IN BINARY MODE.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    READ DATASET xls_file INTO ld_xstring.
    CLOSE DATASET xls_file.
  ELSE.
    " lendo arquivo no PC do usuário
    cl_gui_frontend_services=>gui_upload(
      EXPORTING
        filename                = xls_file
        filetype                = 'BIN'
      CHANGING
        data_tab                = lt_solix
      EXCEPTIONS
        file_open_error         = 1
        file_read_error         = 2
        no_batch                = 3
        gui_refuse_filetransfer = 4
        invalid_type            = 5
        no_authority            = 6
        unknown_error           = 7
        bad_data_format         = 8
        header_not_allowed      = 9
        separator_not_allowed   = 10
        header_too_long         = 11
        unknown_dp_error        = 12
        access_denied           = 13
        dp_out_of_memory        = 14
        disk_full               = 15
        dp_timeout              = 16
        not_supported_by_gui    = 17
        error_no_gui            = 18
        others                  = 19
    ).

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    ld_xstring = cl_bcs_convert=>solix_to_xstring( it_solix = lt_solix ).
  ENDIF.

  lo_excel = new cl_fdt_xl_spreadsheet(
      document_name = xls_file
      xdocument     = ld_xstring
  ).

  " Planilhas
  lo_excel->if_fdt_doc_spreadsheet~get_worksheet_names(
    IMPORTING
      worksheet_names = lt_worksheet_name
  ).

  IF lines( lt_worksheet_name ) = 0.
    EXIT.
  ENDIF.

  " lendo apenas a primeira planilha
  CLEAR ld_worksheet_name.
  READ TABLE lt_worksheet_name INTO ld_worksheet_name INDEX 1.

  " transferindo dados do XLS para uma tabela interna
  lo_worksheet_itab = lo_excel->if_fdt_doc_spreadsheet~get_itab_from_worksheet( worksheet_name = ld_worksheet_name ).
  ASSIGN lo_worksheet_itab->* TO <lt_worksheet>.

  " convertendo dados da tabela interna genérica para a tabela interna de saída
  LOOP AT <lt_worksheet> ASSIGNING <ls_worksheet>.
    " ignorando a linha de cabeçalho
    IF sy-tabix = 1.
      CONTINUE.
    ENDIF.

    APPEND INITIAL LINE TO itab ASSIGNING <ls_itab>.
    DO.
      ASSIGN COMPONENT sy-index OF STRUCTURE <ls_worksheet> TO <ld_value_from>.
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.

      ASSIGN COMPONENT sy-index OF STRUCTURE <ls_itab> TO <ld_value_to>.
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.

      " 01/02/2025 tratando erro com valores decimais interpretados pelo excel
      " onde converte o valor 0.149 em algo como 1.4999999999999999E-2
      TRY.
        <ld_value_to> = <ld_value_from>.
      CATCH CX_SY_CONVERSION_NO_NUMBER INTO DATA(lo_ex).
        ld_valuef     = <ld_value_from>.
        ld_valuef     = cl_abap_math=>round_f_to_15_decs( f_in = ld_valuef ).
        ld_valuedecf  = ld_valuef.
        ld_valuep     = ld_valuedecf.
        <ld_value_to> = ld_valuep.
      ENDTRY.
    ENDDO.
  ENDLOOP.
endmethod.
ENDCLASS.
