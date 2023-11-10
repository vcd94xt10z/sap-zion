class ZCX_EXCEPTION definition
  public
  inheriting from CX_STATIC_CHECK
  create public .

public section.

  data MESSAGE type STRING .

  methods CONSTRUCTOR
    importing
      !TEXTID like TEXTID optional
      !PREVIOUS like PREVIOUS optional
      !MESSAGE type STRING optional .
  methods GET_MESSAGE
    returning
      value(MESSAGE) type STRING .
protected section.
private section.
ENDCLASS.



CLASS ZCX_EXCEPTION IMPLEMENTATION.


  method CONSTRUCTOR.
CALL METHOD SUPER->CONSTRUCTOR
EXPORTING
TEXTID = TEXTID
PREVIOUS = PREVIOUS
.
me->MESSAGE = MESSAGE .
  endmethod.


  method GET_MESSAGE.
    message = me->message.
  endmethod.
ENDCLASS.
