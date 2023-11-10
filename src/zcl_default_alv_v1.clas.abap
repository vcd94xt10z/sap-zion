class ZCL_DEFAULT_ALV_V1 definition
  public
  inheriting from ZCL_ABSTRACT_ALV_V1
  create public .

public section.
  METHODS handle_data_changed          REDEFINITION.
  METHODS handle_data_changed_finished REDEFINITION.
  METHODS handle_double_click          REDEFINITION.
  METHODS handle_enter                 REDEFINITION.
  METHODS handle_hotspot_click         REDEFINITION.
protected section.
private section.
ENDCLASS.



CLASS ZCL_DEFAULT_ALV_V1 IMPLEMENTATION.


  method handle_data_changed.
  ENDMETHOD.


  method handle_data_changed_finished.
  ENDMETHOD.


  method handle_double_click.
  ENDMETHOD.


  method handle_enter.
  ENDMETHOD.


  method handle_hotspot_click.
  ENDMETHOD.
ENDCLASS.
