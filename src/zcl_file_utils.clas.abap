*
* Autor Vinicius Cesar Dias
* Projeto https://github.com/vcd94xt10z/sap-zion
* Versão 0.3 16/02/2026
*
class ZCL_FILE_UTILS definition
  public
  create public .

public section.

  types:
    BEGIN OF MY_FILE
       , filename    TYPE string
       , fullpath    TYPE string
       , filesize    TYPE int4
       , extension   TYPE string
       , type        TYPE char1 " F or D
       , owner       TYPE string
       , create_date TYPE datum
       , create_time TYPE uzeit
       , change_date TYPE datum
       , change_time TYPE uzeit
       , chmod       TYPE char4
       , END OF my_file .
  types:
    my_file_t TYPE STANDARD TABLE OF my_file .

  class-methods DOWNLOAD_USER_BIN_FILE
    importing
      !ID_FILE type ANY
      !ID_CONTENT type XSTRING
    returning
      value(RD_SUBRC) type INT4 .
  class-methods GET_FILENAME_EXTENSION
    importing
      value(ID_FILENAME) type ANY
    returning
      value(RD_EXTENSION) type STRING .
  class-methods GET_FOLDER_SEPARATOR
    importing
      !ID_FOLDER type STRING
    returning
      value(RD_SEPARATOR) type STRING .
  class-methods GET_PARENT_FOLDER
    importing
      value(ID_FOLDER) type ANY
    exporting
      value(ED_PARENT) type ANY .
  class-methods LOAD_USER_TEXT_FILE
    importing
      !ID_FILE type STRING
    returning
      value(RD_CONTENT) type STRING .
  class-methods MOVE_FILE_FROM_PC_TO_SERVER
    importing
      value(ID_SERVER_FULLPATH) type ANY
      value(ID_PC_FULLPATH) type ANY
    exporting
      value(ED_ERROR_MESSAGE) type ANY .
  class-methods MOVE_FILE_FROM_SERVER_TO_PC
    importing
      value(ID_SERVER_FULLPATH) type ANY
      value(ID_PC_FULLPATH) type ANY
      value(ID_PC_SHOW_PROGRESS) type FLAG
    exporting
      value(ED_ERROR_MESSAGE) type ANY .
  class-methods PC_CREATE_FOLDER
    importing
      value(ID_FOLDER) type ANY
    exporting
      value(ED_ERROR_MESSAGE) type ANY .
  class-methods PC_DELETE_FILE
    importing
      value(ID_FULLPATH) type ANY
    exporting
      value(ED_ERROR_MESSAGE) type ANY .
  class-methods PC_DELETE_FOLDER
    importing
      value(ID_FOLDER) type ANY
    exporting
      value(ED_ERROR_MESSAGE) type ANY .
  class-methods PC_MOVE_FILE
    importing
      value(ID_FROM) type ANY
      value(ID_TO) type ANY
    exporting
      value(ED_ERROR_MESSAGE) type ANY .
  class-methods REQUEST_USER_FILE
    importing
      value(ID_DEFAULT_FILENAME) type ANY optional
      value(ID_DEFAULT_EXTENSION) type ANY optional
      value(ID_FILE_FILTER) type ANY optional
    returning
      value(RD_FILE) type STRING .
  class-methods SERVER_CREATE_FOLDER
    importing
      value(ID_FOLDER) type ANY
    exporting
      value(ED_ERROR_MESSAGE) type ANY .
  class-methods SERVER_DELETE_FILE
    importing
      value(ID_FULLPATH) type ANY
    exporting
      value(ED_ERROR_MESSAGE) type ANY
      value(ED_SUBRC) type SYSUBRC .
  class-methods SERVER_DELETE_FOLDER
    importing
      value(ID_FULLPATH) type ANY
    exporting
      value(ED_ERROR_MESSAGE) type ANY
      value(ED_SUBRC) type SYSUBRC .
  class-methods SERVER_FOLDER_CAN_WRITE
    importing
      value(ID_FOLDER) type ANY
    returning
      value(RD_BOOL) type ABAP_BOOL .
  class-methods SERVER_FOLDER_EXISTS
    importing
      value(ID_FOLDER) type ANY
    returning
      value(RD_BOOL) type ABAP_BOOL .
  class-methods SERVER_LIST_FOLDER
    importing
      value(ID_FOLDER) type ANY
    exporting
      value(ET_FILE_LIST) type MY_FILE_T
      value(ED_ERROR_MESSAGE) type STRING .
  class-methods SERVER_MOVE_FILE
    importing
      value(ID_FROM) type ANY
      value(ID_TO) type ANY
    exporting
      value(ED_ERROR_MESSAGE) type ANY .
  class-methods SPLIT_FOLDER_FILENAME
    importing
      value(ID_FULLPATH) type ANY
    exporting
      value(ED_FOLDER) type ANY
      value(ED_FILENAME) type ANY .
protected section.
private section.
ENDCLASS.



CLASS ZCL_FILE_UTILS IMPLEMENTATION.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ZCL_FILE_UTILS=>DOWNLOAD_USER_BIN_FILE
* +-------------------------------------------------------------------------------------------------+
* | [--->] ID_FILE                        TYPE        ANY
* | [--->] ID_CONTENT                     TYPE        XSTRING
* | [<-()] RD_SUBRC                       TYPE        INT4
* +--------------------------------------------------------------------------------------</SIGNATURE>
method DOWNLOAD_USER_BIN_FILE.
  DATA: lt_content TYPE solix_tab.

  " convertendo em tabela SOLIX
  lt_content = cl_bcs_convert=>xstring_to_solix( EXPORTING iv_xstring = id_content ).

  cl_gui_frontend_services=>gui_download(
    EXPORTING
      bin_filesize              = xstrlen( id_content )
      filename                  = id_file
      filetype                  = 'BIN'
    CHANGING
      data_tab                  = lt_content
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

  rd_subrc = sy-subrc.
endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ZCL_FILE_UTILS=>GET_FILENAME_EXTENSION
* +-------------------------------------------------------------------------------------------------+
* | [--->] ID_FILENAME                    TYPE        ANY
* | [<-()] RD_EXTENSION                   TYPE        STRING
* +--------------------------------------------------------------------------------------</SIGNATURE>
method GET_FILENAME_EXTENSION.
  DATA: ld_size  TYPE int4.
  DATA: lt_piece TYPE STANDARD TABLE OF string.
  DATA: ld_piece TYPE string.

  CLEAR rd_extension.

  IF id_filename = ''.
    RETURN.
  ENDIF.

  TRANSLATE id_filename TO UPPER CASE.

  SPLIT id_filename AT '.' INTO TABLE lt_piece.
  IF lines( lt_piece ) <= 0.
    rd_extension = id_filename.
    RETURN.
  ENDIF.

  ld_size = lines( lt_piece ).
  READ TABLE lt_piece INTO ld_piece INDEX ld_size.
  IF sy-subrc <> 0.
    rd_extension = id_filename.
    RETURN.
  ENDIF.

  rd_extension = ld_piece.
endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ZCL_FILE_UTILS=>GET_FOLDER_SEPARATOR
* +-------------------------------------------------------------------------------------------------+
* | [--->] ID_FOLDER                      TYPE        STRING
* | [<-()] RD_SEPARATOR                   TYPE        STRING
* +--------------------------------------------------------------------------------------</SIGNATURE>
method GET_FOLDER_SEPARATOR.
  " detectando separador
  rd_separator = '/'.
  IF id_folder CS '\\'.
    rd_separator = '\\'.
  ELSEIF id_folder CS '\'.
    rd_separator = '\'.
  ENDIF.
endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ZCL_FILE_UTILS=>GET_PARENT_FOLDER
* +-------------------------------------------------------------------------------------------------+
* | [--->] ID_FOLDER                      TYPE        ANY
* | [<---] ED_PARENT                      TYPE        ANY
* +--------------------------------------------------------------------------------------</SIGNATURE>
method GET_PARENT_FOLDER.
  DATA: ld_size      TYPE int4.
  DATA: ld_separator TYPE string.
  DATA: lt_result    TYPE match_result_tab.
  DATA: ls_result    LIKE LINE OF lt_result.
  DATA: ld_string    TYPE string.
  DATA: ld_offset    TYPE int4.
  DATA: lt_string    TYPE STANDARD TABLE OF string.

  CLEAR ed_parent.

  IF id_folder = ''.
    RETURN.
  ENDIF.

  " detectando separador
  ld_separator = '/'.
  IF id_folder CS '\\'.
    ld_separator = '\\'.
  ELSEIF id_folder CS '\'.
    ld_separator = '\'.
  ELSEIF id_folder CS '\\'.
    ld_separator = '\\'.
  ELSEIF id_folder CS '//'.
    ld_separator = '//'.
  ENDIF.

  " root
  IF id_folder = ld_separator.
    ed_parent = id_folder.
    RETURN.
  ENDIF.

  SPLIT id_folder AT ld_separator INTO TABLE lt_string.
  ld_size = lines( lt_string ).
  IF ld_size = 0 OR ld_size = 1.
    ed_parent = id_folder.
    RETURN.
  ENDIF.

  CLEAR lt_result.
  FIND ALL OCCURRENCES OF ld_separator IN id_folder RESULTS lt_result.
  ld_size = lines( lt_result ).

  READ TABLE lt_result INTO ls_result INDEX ld_size.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  " verificando se o diretório termina com o separador
  ld_offset = ls_result-offset + 1.
  ld_string = id_folder+ld_offset.
  IF ld_string = ''.
    ld_size = ld_size - 1.
    READ TABLE lt_result INTO ls_result INDEX ld_size.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    IF ls_result-offset > 0.
      ed_parent = id_folder(ls_result-offset).
    ENDIF.
  ELSE.
    IF ls_result-offset > 0.
      ed_parent = id_folder(ls_result-offset).
    ENDIF.
  ENDIF.

  ed_parent = |{ ed_parent }{ ld_separator }|.
endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ZCL_FILE_UTILS=>LOAD_USER_TEXT_FILE
* +-------------------------------------------------------------------------------------------------+
* | [--->] ID_FILE                        TYPE        STRING
* | [<-()] RD_CONTENT                     TYPE        STRING
* +--------------------------------------------------------------------------------------</SIGNATURE>
method LOAD_USER_TEXT_FILE.
  DATA: lt_content TYPE STANDARD TABLE OF string.

  CALL FUNCTION 'GUI_UPLOAD'
    EXPORTING
      filename = id_file
      filetype = 'ASC'
    TABLES
      data_tab = lt_content.

  IF lines( lt_content ) > 0.
    CONCATENATE LINES OF lt_content
           INTO rd_content
   SEPARATED BY cl_abap_char_utilities=>newline.
  ENDIF.
endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ZCL_FILE_UTILS=>MOVE_FILE_FROM_PC_TO_SERVER
* +-------------------------------------------------------------------------------------------------+
* | [--->] ID_SERVER_FULLPATH             TYPE        ANY
* | [--->] ID_PC_FULLPATH                 TYPE        ANY
* | [<---] ED_ERROR_MESSAGE               TYPE        ANY
* +--------------------------------------------------------------------------------------</SIGNATURE>
method MOVE_FILE_FROM_PC_TO_SERVER.
  DATA: ld_server_fullpath(2048) TYPE c.
  DATA: ld_pc_fullpath(2048)     TYPE c.
  DATA: ld_size                  TYPE int4.
  DATA: lt_data                  TYPE STANDARD TABLE OF tbl1024.
  DATA: ld_data                  LIKE LINE OF lt_data.
  DATA: ld_buffer_size           TYPE int4.
  DATA: ld_rest                  TYPE int4.

  CLEAR ed_error_message.

  ld_pc_fullpath     = id_pc_fullpath.
  ld_server_fullpath = id_server_fullpath.

  " carregando dados para a memória
  CLEAR ld_size.
  CLEAR lt_data.
  CALL FUNCTION 'SCMS_UPLOAD'
    EXPORTING
      filename = ld_pc_fullpath
      binary   = 'X'
      frontend = 'X'
    IMPORTING
      filesize = ld_size
    TABLES
      data     = lt_data
    EXCEPTIONS
      error    = 1
      others   = 2.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid
       TYPE sy-msgty
     NUMBER sy-msgno
       WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
       INTO ed_error_message.
    RETURN.
  ENDIF.

  " gravando arquivo no servidor
  OPEN DATASET id_server_fullpath FOR OUTPUT IN BINARY MODE.
  IF sy-subrc <> 0.
    ed_error_message = 'Erro ao abrir arquivo para gravação'.
    RETURN.
  ENDIF.

  ld_buffer_size = 1024.
  ld_rest        = ld_size.

  LOOP AT lt_data INTO ld_data.
    IF ld_rest = 0.
      EXIT.
    ENDIF.

    IF ld_rest < ld_buffer_size.
      TRANSFER ld_data TO id_server_fullpath LENGTH ld_rest.
      ld_rest = 0.
    ELSE.
      TRANSFER ld_data TO id_server_fullpath LENGTH ld_buffer_size.
      ld_rest = ld_rest - ld_buffer_size.
    ENDIF.
  ENDLOOP.

  CLOSE DATASET id_server_fullpath.
endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ZCL_FILE_UTILS=>MOVE_FILE_FROM_SERVER_TO_PC
* +-------------------------------------------------------------------------------------------------+
* | [--->] ID_SERVER_FULLPATH             TYPE        ANY
* | [--->] ID_PC_FULLPATH                 TYPE        ANY
* | [--->] ID_PC_SHOW_PROGRESS            TYPE        FLAG
* | [<---] ED_ERROR_MESSAGE               TYPE        ANY
* +--------------------------------------------------------------------------------------</SIGNATURE>
method MOVE_FILE_FROM_SERVER_TO_PC.
  " https://community.sap.com/t5/application-development-and-automation-discussions/how-to-download-file-from-application-server/m-p/5546520
  CONSTANTS blocksize   TYPE i VALUE 524287.
  CONSTANTS packagesize TYPE i VALUE 8.

  TYPES ty_datablock(blocksize) TYPE x.
  DATA lv_fil  TYPE epsf-epsfilnam.
  DATA lv_dir  TYPE epsf-epsdirnam.

  DATA ls_data TYPE ty_datablock.
  DATA lt_data TYPE STANDARD TABLE OF ty_datablock.

  DATA lv_block_len        TYPE i.
  DATA lv_package_len      TYPE i.
  DATA lv_subrc            TYPE sy-subrc.
  DATA lv_msgv1            LIKE sy-msgv1.
  DATA lv_processed_so_far TYPE p.
  DATA lv_append           TYPE c.
  DATA lv_status           TYPE string.
  DATA lv_filesize         TYPE p.
  DATA lv_percent          TYPE i.

  CLEAR ed_error_message.

  "Determine size
  split_folder_filename(
    EXPORTING
      id_fullpath = id_server_fullpath
    IMPORTING
      ed_folder   = lv_dir
      ed_filename = lv_fil
  ).

  CALL FUNCTION 'EPS_GET_FILE_ATTRIBUTES'
    EXPORTING
      file_name      = lv_fil
      dir_name       = lv_dir
    IMPORTING
      file_size_long = lv_filesize
    EXCEPTIONS
      others         = 1.

  IF sy-subrc <> 0.
    ed_error_message = 'Erro ao ler atributos do arquivo'.
    RETURN.
  ENDIF.

  "Open the file on application server
  OPEN DATASET id_server_fullpath FOR INPUT IN BINARY MODE MESSAGE lv_msgv1.
  IF sy-subrc <> 0.
    ed_error_message = 'Erro ao ler arquivo no servidor (OPEN DATASET)'.
    RETURN.
  ENDIF.

  lv_processed_so_far = 0.
  DO.
    REFRESH lt_data.
    lv_package_len = 0.
    DO packagesize TIMES.
      CLEAR ls_data.
      CLEAR lv_block_len.
      READ DATASET id_server_fullpath INTO ls_data MAXIMUM LENGTH blocksize LENGTH lv_block_len.
      lv_subrc = sy-subrc.
      IF lv_block_len > 0.
        lv_package_len = lv_package_len + lv_block_len.
        APPEND ls_data TO lt_data.
      ENDIF.
      "End of file
      IF lv_subrc <> 0.
        EXIT.
      ENDIF.
    ENDDO.

    IF lv_package_len > 0.
      "Put file to client
      IF lv_processed_so_far = 0.
        lv_append = ' '.
      ELSE.
        lv_append = 'X'.
      ENDIF.
      CALL FUNCTION 'GUI_DOWNLOAD'
        EXPORTING
          bin_filesize         = lv_package_len
          filename             = id_pc_fullpath
          filetype             = 'BIN'
          append               = lv_append
          show_transfer_status = abap_false
        TABLES
          data_tab             = lt_data.

      IF id_pc_show_progress = 'X'.
        lv_processed_so_far = lv_processed_so_far + lv_package_len.
        "Status display
        lv_percent = lv_processed_so_far * 100 / lv_filesize.
        lv_status = |{ lv_percent }% - { lv_processed_so_far } bytes downloaded of { lv_filesize }|.
        CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
          EXPORTING          "percentage = lv_percent - will make it fash
            text = lv_status.
      ENDIF.
    ENDIF.

    "End of file
    IF lv_subrc <> 0.
      EXIT.
    ENDIF.
  ENDDO.

  "Close the file on application server
  CLOSE DATASET id_server_fullpath.
endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ZCL_FILE_UTILS=>PC_CREATE_FOLDER
* +-------------------------------------------------------------------------------------------------+
* | [--->] ID_FOLDER                      TYPE        ANY
* | [<---] ED_ERROR_MESSAGE               TYPE        ANY
* +--------------------------------------------------------------------------------------</SIGNATURE>
method PC_CREATE_FOLDER.
  DATA: ld_rc TYPE int4.

  CLEAR ed_error_message.

  IF id_folder = ''.
    ed_error_message = 'Diretório vazio'.
    RETURN.
  ENDIF.

  cl_gui_frontend_services=>directory_create(
    EXPORTING
      directory                = id_folder
    CHANGING
      rc                       = ld_rc
    EXCEPTIONS
      directory_create_failed  = 1                " Could not create directory
      cntl_error               = 2                " A Control Error Occurred
      error_no_gui             = 3                " No GUI available
      directory_access_denied  = 4                " Access denied
      directory_already_exists = 5                " Directory already exists
      path_not_found           = 6                " Path does not exist
      unknown_error            = 7                " Unknown error
      not_supported_by_gui     = 8                " GUI does not support this
      wrong_parameter          = 9                " Wrong parameter
      others                   = 10
  ).

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
       WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
       INTO ed_error_message.
  ENDIF.
endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ZCL_FILE_UTILS=>PC_DELETE_FILE
* +-------------------------------------------------------------------------------------------------+
* | [--->] ID_FULLPATH                    TYPE        ANY
* | [<---] ED_ERROR_MESSAGE               TYPE        ANY
* +--------------------------------------------------------------------------------------</SIGNATURE>
method PC_DELETE_FILE.
  DATA: ld_rc TYPE int4.

  CLEAR ed_error_message.

  IF id_fullpath = ''.
    ed_error_message = 'Diretório vazio'.
    RETURN.
  ENDIF.

  cl_gui_frontend_services=>file_delete(
    EXPORTING
      filename             = id_fullpath
    CHANGING
      rc                   = ld_rc
    EXCEPTIONS
      file_delete_failed   = 1                " Could not delete file
      cntl_error           = 2                " Control error
      error_no_gui         = 3                " Error: No GUI
      file_not_found       = 4                " File not found
      access_denied        = 5                " Access denied
      unknown_error        = 6                " Unknown error
      not_supported_by_gui = 7                " GUI does not support this
      wrong_parameter      = 8                " Wrong parameter
      others               = 9
  ).

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
       WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
       INTO ed_error_message.
  ENDIF.
endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ZCL_FILE_UTILS=>PC_DELETE_FOLDER
* +-------------------------------------------------------------------------------------------------+
* | [--->] ID_FOLDER                      TYPE        ANY
* | [<---] ED_ERROR_MESSAGE               TYPE        ANY
* +--------------------------------------------------------------------------------------</SIGNATURE>
method PC_DELETE_FOLDER.
  DATA: ld_rc TYPE int4.

  CLEAR ed_error_message.

  IF id_folder = ''.
    ed_error_message = 'Diretório vazio'.
    RETURN.
  ENDIF.

  cl_gui_frontend_services=>directory_delete(
    EXPORTING
      directory               = id_folder
    CHANGING
      rc                      = ld_rc
    EXCEPTIONS
      directory_delete_failed = 1                " Could not delete directory
      cntl_error              = 2                " Control error
      error_no_gui            = 3                " No GUI available
      path_not_found          = 4                " Path not found
      directory_access_denied = 5                " Access denied
      unknown_error           = 6                " Unknown error
      not_supported_by_gui    = 7                " GUI does not support this
      wrong_parameter         = 8                " Wrong parameter
      others                  = 9
  ).

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
       WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
       INTO ed_error_message.
  ENDIF.
endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ZCL_FILE_UTILS=>PC_MOVE_FILE
* +-------------------------------------------------------------------------------------------------+
* | [--->] ID_FROM                        TYPE        ANY
* | [--->] ID_TO                          TYPE        ANY
* | [<---] ED_ERROR_MESSAGE               TYPE        ANY
* +--------------------------------------------------------------------------------------</SIGNATURE>
method PC_MOVE_FILE.
  DATA: ld_rc TYPE int4.

  CLEAR ed_error_message.

  IF id_from = ''.
    ed_error_message = 'Arquivo origem vazio'.
    RETURN.
  ENDIF.

  IF id_to = ''.
    ed_error_message = 'Arquivo destino vazio'.
    RETURN.
  ENDIF.

  cl_gui_frontend_services=>file_copy(
    EXPORTING
      source               = id_from
      destination          = id_to
*      overwrite            = space            " Overrides if Destination Exists
    EXCEPTIONS
      cntl_error           = 1                " Control error
      error_no_gui         = 2                " No GUI Available
      wrong_parameter      = 3                " Incorrect parameter
      disk_full            = 4                " Disk full
      access_denied        = 5                " Access Denied to Source or Destination File
      file_not_found       = 6                " Source File not Found
      destination_exists   = 7                " Destination Already Exists
      unknown_error        = 8                " Unknown error
      path_not_found       = 9                " Path to Which You Want to Copy File(s) Does not Exist
      disk_write_protect   = 10               " Disk Is Write-Protected
      drive_not_ready      = 11               " Disk drive not ready
      not_supported_by_gui = 12               " GUI does not support this
      others               = 13
  ).

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
       WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
       INTO ed_error_message.
    RETURN.
  ENDIF.

  cl_gui_frontend_services=>file_delete(
    EXPORTING
      filename             = id_from
    CHANGING
      rc                   = ld_rc
    EXCEPTIONS
      file_delete_failed   = 1                " Could not delete file
      cntl_error           = 2                " Control error
      error_no_gui         = 3                " Error: No GUI
      file_not_found       = 4                " File not found
      access_denied        = 5                " Access denied
      unknown_error        = 6                " Unknown error
      not_supported_by_gui = 7                " GUI does not support this
      wrong_parameter      = 8                " Wrong parameter
      others               = 9
  ).

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
       WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
       INTO ed_error_message.
    RETURN.
  ENDIF.
endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ZCL_FILE_UTILS=>REQUEST_USER_FILE
* +-------------------------------------------------------------------------------------------------+
* | [--->] ID_DEFAULT_FILENAME            TYPE        ANY(optional)
* | [--->] ID_DEFAULT_EXTENSION           TYPE        ANY(optional)
* | [--->] ID_FILE_FILTER                 TYPE        ANY(optional)
* | [<-()] RD_FILE                        TYPE        STRING
* +--------------------------------------------------------------------------------------</SIGNATURE>
method REQUEST_USER_FILE.
  DATA: ld_rc          TYPE int4,
        ld_user_action TYPE int4.

  DATA: lt_file TYPE TABLE OF file_table,
        ls_file TYPE file_table.

  CLEAR: lt_file.

  CALL METHOD cl_gui_frontend_services=>file_open_dialog
    EXPORTING
      window_title            = 'Escolha o arquivo...'
      default_filename        = CONV string( id_default_filename )
      default_extension       = CONV string( id_default_extension ) "  '*.xml'
      file_filter             = CONV string( id_file_filter )      "  'XML (*.xml) '
      multiselection          = space
    CHANGING
      file_table              = lt_file
      rc                      = ld_rc
      user_action             = ld_user_action
    EXCEPTIONS
      file_open_dialog_failed = 1
      cntl_error              = 2
      error_no_gui            = 3
      not_supported_by_gui    = 4
      OTHERS                  = 5.

  IF sy-subrc EQ 0.
    READ TABLE lt_file INTO ls_file INDEX 1.
    IF sy-subrc = 0.
      MOVE ls_file TO rd_file.
    ENDIF.
  ENDIF.
endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ZCL_FILE_UTILS=>SERVER_CREATE_FOLDER
* +-------------------------------------------------------------------------------------------------+
* | [--->] ID_FOLDER                      TYPE        ANY
* | [<---] ED_ERROR_MESSAGE               TYPE        ANY
* +--------------------------------------------------------------------------------------</SIGNATURE>
method SERVER_CREATE_FOLDER.
  DATA: ld_command1(70) TYPE c.

  CLEAR ed_error_message.

  IF id_folder = ''.
    ed_error_message = 'Diretório vazio'.
    RETURN.
  ENDIF.

  ld_command1 = |mkdir -p { id_folder }|.

  CALL 'SYSTEM' ID 'COMMAND' FIELD ld_command1.

  IF server_folder_exists( id_folder = id_folder ) = abap_false.
    ed_error_message = 'Erro ao criar diretório'.
  ENDIF.
endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ZCL_FILE_UTILS=>SERVER_DELETE_FILE
* +-------------------------------------------------------------------------------------------------+
* | [--->] ID_FULLPATH                    TYPE        ANY
* | [<---] ED_ERROR_MESSAGE               TYPE        ANY
* | [<---] ED_SUBRC                       TYPE        SYSUBRC
* +--------------------------------------------------------------------------------------</SIGNATURE>
method SERVER_DELETE_FILE.
  CLEAR ed_error_message.

  IF id_fullpath = ''.
    ed_error_message = 'Arquivo vazio'.
    RETURN.
  ENDIF.

  DELETE DATASET id_fullpath.
  ed_subrc = sy-subrc.
  IF ed_subrc <> 0.
    CLOSE DATASET id_fullpath.
    ed_error_message = |Erro ao deletar arquivo { id_fullpath }|.
  ELSE.
    CLOSE DATASET id_fullpath.
  ENDIF.
endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ZCL_FILE_UTILS=>SERVER_DELETE_FOLDER
* +-------------------------------------------------------------------------------------------------+
* | [--->] ID_FULLPATH                    TYPE        ANY
* | [<---] ED_ERROR_MESSAGE               TYPE        ANY
* | [<---] ED_SUBRC                       TYPE        SYSUBRC
* +--------------------------------------------------------------------------------------</SIGNATURE>
method SERVER_DELETE_FOLDER.
  DATA: lt_file         TYPE my_file_t.
  DATA: ld_command1(70) TYPE c.

  CLEAR ed_error_message.

  IF id_fullpath = ''.
    ed_error_message = 'Arquivo vazio'.
    RETURN.
  ENDIF.

  CLEAR lt_file.
  server_list_folder(
    EXPORTING
      id_folder    = id_fullpath
    IMPORTING
      et_file_list = lt_file
  ).
  IF lines( lt_file ) > 0.
    ed_error_message = 'O diretório não esta vazio'.
    RETURN.
  ENDIF.

  CLEAR ed_error_message.

  ld_command1 = |rmdir { id_fullpath }|.

  CALL 'SYSTEM' ID 'COMMAND' FIELD ld_command1.

  IF server_folder_exists( id_folder = id_fullpath ) = abap_true.
    ed_error_message = 'Erro ao deletar diretório'.
  ENDIF.
endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ZCL_FILE_UTILS=>SERVER_FOLDER_CAN_WRITE
* +-------------------------------------------------------------------------------------------------+
* | [--->] ID_FOLDER                      TYPE        ANY
* | [<-()] RD_BOOL                        TYPE        ABAP_BOOL
* +--------------------------------------------------------------------------------------</SIGNATURE>
method SERVER_FOLDER_CAN_WRITE.
  DATA: ld_file TYPE string.

  rd_bool = abap_false.

  ld_file = |{ id_folder }temp_file_{ sy-datum }{ sy-uzeit }{ sy-uname }.tmp|.

  " tentando criar o arquivo
  OPEN DATASET ld_file FOR OUTPUT IN TEXT MODE ENCODING UTF-8.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  TRANSFER 'Teste' TO ld_file.
  IF sy-subrc <> 0.
    CLOSE DATASET ld_file.
    RETURN.
  ENDIF.

  CLOSE DATASET ld_file.

  " deletando arquivo temporário
  DELETE DATASET ld_file.
  IF sy-subrc <> 0.
    CLOSE DATASET ld_file.
    RETURN.
  ENDIF.

  rd_bool = abap_true.
endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ZCL_FILE_UTILS=>SERVER_FOLDER_EXISTS
* +-------------------------------------------------------------------------------------------------+
* | [--->] ID_FOLDER                      TYPE        ANY
* | [<-()] RD_BOOL                        TYPE        ABAP_BOOL
* +--------------------------------------------------------------------------------------</SIGNATURE>
method SERVER_FOLDER_EXISTS.
  DATA: ld_directory TYPE btch0000-text80.

  IF id_folder = ''.
    rd_bool = abap_false.
    RETURN.
  ENDIF.

  ld_directory = id_folder.

  CALL FUNCTION 'PFL_CHECK_DIRECTORY'
   EXPORTING
     DIRECTORY                         = ld_directory
   EXCEPTIONS
     pfl_dir_not_exist           = 1
     pfl_permission_denied       = 2
     pfl_cant_build_dataset_name = 3
     pfl_file_not_exist          = 4
     pfl_authorization_missing   = 5
     others                      = 6.

  IF sy-subrc = 0.
    rd_bool = abap_true.
  ELSE.
    rd_bool = abap_false.
  ENDIF.
endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ZCL_FILE_UTILS=>SERVER_LIST_FOLDER
* +-------------------------------------------------------------------------------------------------+
* | [--->] ID_FOLDER                      TYPE        ANY
* | [<---] ET_FILE_LIST                   TYPE        MY_FILE_T
* | [<---] ED_ERROR_MESSAGE               TYPE        STRING
* +--------------------------------------------------------------------------------------</SIGNATURE>
method SERVER_LIST_FOLDER.
  CONSTANTS: c_file_list_update TYPE c VALUE 'U'.

  types: begin of ly_file,
         dirname     type dirname_al11,   " name of directory
         name        type filename_al11,  " name of entry
         type(10)    type c,              " type of entry.
         len(8)      type p DECIMALS 0,              " length in bytes.
         owner       type fileowner_al11, " owner of the entry.
         mtime(6)    type p DECIMALS 0,              " last mod.date, sec since 1970
         mode(9)     type c,              " like "rwx-r-x--x": prot. mode
         useable(1)  type c,
         subrc(4)    type c,
         errno(3)    type c,
         errmsg(40)  type c,
         mod_date    type d,
         mod_time(8) type c,              " hh:mm:ss
         seen(1)     type c,
         changed(1)  type c,
         status(1)   type c,
       end of ly_file.

  DATA: ld_errno(3)     TYPE c.
  DATA: ld_errmsg(40)   TYPE c.
  DATA: ld_folder(1024) TYPE c.
  DATA: lt_file         TYPE STANDARD TABLE OF ly_file WITH NON-UNIQUE SORTED KEY K1 COMPONENTS NAME.
  DATA: ls_file         TYPE ly_file.
  DATA: ld_separator    TYPE string.

  DATA: ls_file_list LIKE LINE OF et_file_list.

  DATA: a_must_cs(1) TYPE c.
  DATA: no_cs        VALUE ' '.

  DATA: errcnt      TYPE i VALUE 0.
  DATA: a_operation TYPE c VALUE 'I'.

  FIELD-SYMBOLS: <ls_file> TYPE ly_file.

  CLEAR ld_errno.
  CLEAR ld_errmsg.
  CLEAR lt_file.
  CLEAR et_file_list.

  ld_folder = id_folder.

  CALL METHOD zcl_file_utils=>get_folder_separator
    EXPORTING
      id_folder    = CONV string( id_folder )
    RECEIVING
      rd_separator = ld_separator.

  " garantindo que não tenha nenhuma solicitação anterior em aberto
  call 'C_DIR_READ_FINISH'
      id 'ERRNO'  field ld_errno
      id 'ERRMSG' field ld_errmsg.

  call 'C_DIR_READ_START' id 'DIR'    field ld_folder
                          id 'FILE'   field '*'
                          id 'ERRNO'  field ld_errno
                          id 'ERRMSG' field ld_errmsg.

  IF sy-subrc <> 0.
    ed_error_message = |{ ld_errno } { ld_errmsg }|.
    RETURN.
  ENDIF.

  DO.
    clear ls_file.
    call 'C_DIR_READ_NEXT'
      id 'TYPE'   field ls_file-type
      id 'NAME'   field ls_file-name
      id 'LEN'    field ls_file-len
      id 'OWNER'  field ls_file-owner
      id 'MTIME'  field ls_file-mtime
      id 'MODE'   field ls_file-mode
      id 'ERRNO'  field ls_file-errno
      id 'ERRMSG' field ls_file-errmsg.
    ls_file-dirname = ld_folder.
    move sy-subrc to ls_file-subrc.
    case sy-subrc.
      when 0.
        clear: ls_file-errno, ls_file-errmsg.
        case ls_file-type(1).
          when 'F'.                    " normal file.
            perform filename_useable IN PROGRAM RSWATCH0 using ls_file-name changing ls_file-useable.
          when 'f'.                    " normal file.
            perform filename_useable IN PROGRAM RSWATCH0 using ls_file-name changing ls_file-useable.
          when others. " directory, device, fifo, socket,...
            move abap_false  to ls_file-useable.
        endcase.
        if ls_file-len = 0.
          move abap_false to ls_file-useable.
        endif.
      when 1.
        "No more slots available.
        exit.
      when 5.
        "Only NAME is valid due to internal error.
        clear: ls_file-type, ls_file-len, ls_file-owner, ls_file-mtime, ls_file-mode,
               ls_file-errno, ls_file-errmsg.
        ls_file-useable = abap_false.
      when others.
        "possible other return codes (sapaci2.c)
        "3 ... Internal error.
        "4 ... NAME is truncated (Warning only)
        add 1 to errcnt.
        "don't list files with error
        if ls_file-subrc = 3.
          continue.
        endif.
    endcase.
    perform p6_to_date_time_tz IN PROGRAM rstr0400 using ls_file-mtime
                                               ls_file-mod_time
                                               ls_file-mod_date.


    if a_operation eq c_file_list_update.
      read table lt_file with key k1 components name = ls_file-name assigning <ls_file>.

      if sy-subrc eq 0.
        "In case file is found in the list means it already exists, otherwise, file does not exist anymore
        if <ls_file>-type  <> ls_file-type  or
           <ls_file>-len   <> ls_file-len   or
           <ls_file>-owner <> ls_file-owner or
           <ls_file>-mtime <> ls_file-mtime or
           <ls_file>-mode  <> ls_file-mode  or
           <ls_file>-errno <> ls_file-errno.

          ls_file-changed = abap_true.
        endif.
        ls_file-status = abap_true.

        move-corresponding ls_file to <ls_file>.

      else.
        "New File
        ls_file-status = abap_true.

*       * Does the filename contains the requested pattern?
*       * Then store it, else forget it.
        if a_must_cs = no_cs.
          "append ls_file TO lt_file.
        else.
          if ls_file-name cs a_must_cs.
            "append ls_file TO lt_file.
          endif.
        endif.

      endif.
    else.

      "Build a new list
      ls_file-status = abap_true.

*     * Does the filename contains the requested pattern?
*     * Then store it, else forget it.
      if a_must_cs = no_cs.
        "append ls_file TO lt_file.
      else.
        if ls_file-name cs a_must_cs.
          "append ls_file TO lt_file.
        endif.
      endif.
    endif.

    IF ls_file-name = '.' OR ls_file-name = '..'.
      CONTINUE.
    ENDIF.

    REPLACE ALL OCCURRENCES OF REGEX '[^0-9]' IN ls_file-mod_time WITH ''.

    CLEAR ls_file_list.
    ls_file_list-filename = ls_file-name.
    ls_file_list-fullpath = |{ id_folder }{ ls_file-name }|.
    ls_file_list-filesize = ls_file-len.
    ls_file_list-extension = get_filename_extension( id_filename = ls_file_list-filename ).
    ls_file_list-owner     = ls_file_list-owner.
    ls_file_list-type      = 'F'.
    IF ls_file-type(1) = 'd'.
      ls_file_list-type = 'D'.
      ls_file_list-fullpath = |{ ls_file_list-fullpath }{ ld_separator }|.
      ls_file_list-extension = ''.
    ENDIF.
    ls_file_list-create_date = ''.
    ls_file_list-create_time = ''.
    ls_file_list-change_date = ls_file-mod_date.
    ls_file_list-change_time = ls_file-mod_time.
    ls_file_list-chmod       = ls_file-mode.
    APPEND ls_file_list TO et_file_list.
  ENDDO.

  call 'C_DIR_READ_FINISH'
    id 'ERRNO'  field ld_errno
    id 'ERRMSG' field ld_errmsg.
endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ZCL_FILE_UTILS=>SERVER_MOVE_FILE
* +-------------------------------------------------------------------------------------------------+
* | [--->] ID_FROM                        TYPE        ANY
* | [--->] ID_TO                          TYPE        ANY
* | [<---] ED_ERROR_MESSAGE               TYPE        ANY
* +--------------------------------------------------------------------------------------</SIGNATURE>
method SERVER_MOVE_FILE.
  DATA: ld_line(1024) TYPE x.

  CLEAR ed_error_message.

  OPEN DATASET id_from FOR INPUT IN BINARY MODE.
  IF sy-subrc <> 0.
    ed_error_message = 'Erro ao abrir arquivo para leitura'.
    RETURN.
  ENDIF.

  OPEN DATASET id_to FOR OUTPUT IN BINARY MODE.
  IF sy-subrc <> 0.
    ed_error_message = 'Erro ao abrir arquivo para gravação'.
    RETURN.
  ENDIF.

  DO.
    READ DATASET id_from INTO ld_line.
    IF sy-subrc EQ 0.
      TRANSFER ld_line TO id_to.
    ELSE.
      IF ld_line IS NOT INITIAL.
        TRANSFER ld_line TO id_to.
      ENDIF.
      EXIT.
    ENDIF.
  ENDDO.

  DELETE DATASET id_from.

  CLOSE DATASET id_to.
  CLOSE DATASET id_from.
endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ZCL_FILE_UTILS=>SPLIT_FOLDER_FILENAME
* +-------------------------------------------------------------------------------------------------+
* | [--->] ID_FULLPATH                    TYPE        ANY
* | [<---] ED_FOLDER                      TYPE        ANY
* | [<---] ED_FILENAME                    TYPE        ANY
* +--------------------------------------------------------------------------------------</SIGNATURE>
method SPLIT_FOLDER_FILENAME.
  DATA: ld_separator TYPE string.
  DATA: lt_result    TYPE match_result_tab.
  DATA: ls_result    LIKE LINE OF lt_result.
  DATA: ld_size      TYPE int4.
  DATA: ld_index     TYPE int4.

  CLEAR ed_folder.
  CLEAR ed_filename.

  IF id_fullpath = ''.
    RETURN.
  ENDIF.

  " detectando separador
  ld_separator = '/'.
  IF id_fullpath CS '\\'.
    ld_separator = '\\'.
  ELSEIF id_fullpath CS '\'.
    ld_separator = '\'.
  ENDIF.

  CLEAR lt_result.
  FIND ALL OCCURRENCES OF ld_separator IN id_fullpath RESULTS lt_result.
  ld_size = lines( lt_result ).
  IF ld_size <= 0.
    RETURN.
  ENDIF.

  CLEAR ls_result.
  READ TABLE lt_result INTO ls_result INDEX ld_size.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  ld_index         = ls_result-offset + 1.
  ed_folder        = id_fullpath(ld_index).
  ed_filename      = id_fullpath+ld_index.
endmethod.
ENDCLASS.
