FUNCTION Main()
    LOCAL lExito

    lExito := AURA_ChartGroupedBar( { ;
        "data1"   => { 290, 370, 340, 420, 460, 550 }, ;
        "data2"   => { 320, 415, 380, 490, 520, 610 }, ;
        "labels"  => { "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio" }, ;
        "label1"  => "2025", ;
        "label2"  => "2026", ;
        "titulo"  => "Ventas Mensuales (miles de pesos)", ;
        "archivo" => "reporte_ventas.png", ;
        "maxval"  => 0 ;
    } )

    IF lExito
        ? "PNG generado: reporte_ventas.png"
    ELSE
        ? "Error al generar PNG."
    ENDIF

RETURN NIL