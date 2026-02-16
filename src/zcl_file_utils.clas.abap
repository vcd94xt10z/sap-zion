*
* Autor Vinicius Cesar Dias
* Projeto https://github.com/vcd94xt10z/sap-zion
* Versão 0.1
*
class ZCL_FILE_UTILS definition
  public
  create public .

public section.

  class-methods REQUEST_USER_FILE
    importing
      value(ID_DEFAULT_FILENAME) type ANY optional
      value(ID_DEFAULT_EXTENSION) type ANY optional
      value(ID_FILE_FILTER) type ANY optional
    returning
      value(RD_FILE) type STRING .
  class-methods LOAD_USER_TEXT_FILE
    importing
      !ID_FILE type STRING
    returning
      value(RD_CONTENT) type STRING .
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
  class-methods MOVE_FILE_FROM_SERVER_TO_PC
    importing
      value(ID_SERVER_FULLPATH) type ANY
      value(ID_PC_FULLPATH) type ANY
      value(ID_PC_SHOW_PROGRESS) type FLAG
    exporting
      value(ED_ERROR_MESSAGE) type ANY .
  class-methods MOVE_FILE_FROM_PC_TO_SERVER
    importing
      value(ID_SERVER_FULLPATH) type ANY
      value(ID_PC_FULLPATH) type ANY
    exporting
      value(ED_ERROR_MESSAGE) type ANY .
  class-methods SERVER_CREATE_FOLDER
    importing
      value(ID_FOLDER) type ANY
    exporting
      value(ED_ERROR_MESSAGE) type ANY .
  class-methods SERVER_DELETE_FOLDER .
  class-methods SERVER_DELETE_FILE
    importing
      value(ID_FULLPATH) type ANY
    exporting
      value(ED_ERROR_MESSAGE) type ANY
      value(ED_SUBRC) type SYSUBRC .
  class-methods SERVER_FOLDER_EXISTS
    importing
      value(ID_FOLDER) type ANY
    returning
      value(RD_BOOL) type ABAP_BOOL .
  class-methods SERVER_FOLDER_CAN_WRITE
    importing
      value(ID_FOLDER) type ANY
    returning
      value(RD_BOOL) type ABAP_BOOL .
  class-methods PC_CREATE_FOLDER .
  class-methods PC_DELETE_FOLDER .
  class-methods PC_DELETE_FILE .
  class-methods SERVER_MOVE_FILE .
  class-methods PC_MOVE_FILE .
  class-methods SPLIT_FOLDER_FILENAME
    importing
      value(ID_FULLPATH) type ANY
    exporting
      value(ED_FOLDER) type ANY
      value(ED_FILENAME) type ANY .
  class-methods GET_PARENT_FOLDER
    importing
      value(ID_FOLDER) type ANY
    exporting
      value(ED_PARENT) type ANY .
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

  TRANSLATE id_filename TO LOWER CASE.

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
    CONCATENATE LINES OF lt_content INTO rd_content SEPARATED BY cl_abap_char_utilities=>newline.
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
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method PC_CREATE_FOLDER.
  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ZCL_FILE_UTILS=>PC_DELETE_FILE
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method PC_DELETE_FILE.
  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ZCL_FILE_UTILS=>PC_DELETE_FOLDER
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method PC_DELETE_FOLDER.
  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ZCL_FILE_UTILS=>PC_MOVE_FILE
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method PC_MOVE_FILE.
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
  DATA: ld_dirname TYPE branint-dirname.

  CLEAR ed_error_message.

  IF id_folder = ''.
    ed_error_message = 'Diretório vazio'.
    RETURN.
  ENDIF.

  ld_dirname = id_folder.

  TRY.
    CALL FUNCTION 'BRAN_DIR_CREATE'
      EXPORTING
        dirname        = ld_dirname
      EXCEPTIONS
        already_exists = 1
        cant_create    = 2
        error_message  = 3
        others         = 4.
  CATCH cx_root.
  ENDTRY.

  CASE sy-subrc.
    WHEN 0.
      ed_error_message = ''.
    WHEN 1.
      ed_error_message = 'O diretório já existe'.
    WHEN 2.
      ed_error_message = 'Não é possível criar o diretório'.
    WHEN 3.
      ed_error_message = 'Erro ao criar diretório'.
    WHEN OTHERS.
      ed_error_message = 'Erro desconhecido ao criar diretório'.
  ENDCASE.
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
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method SERVER_DELETE_FOLDER.
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
  OPEN DATASET ld_file FOR INPUT IN TEXT MODE ENCODING DEFAULT.
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
* | Static Public Method ZCL_FILE_UTILS=>SERVER_MOVE_FILE
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method SERVER_MOVE_FILE.
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
