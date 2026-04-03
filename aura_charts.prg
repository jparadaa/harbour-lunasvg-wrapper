// ==========================================================
// AURA_CHARTS.PRG - Mini librería de gráficas SVG -> PNG
// ==========================================================

// ----------------------------------------------------------
// FUNCIÓN PÚBLICA: Barras agrupadas + línea de tendencia
// Parámetros (hash):
//   "data1"   => Array numérico serie 1
//   "data2"   => Array numérico serie 2
//   "labels"  => Array etiquetas eje X
//   "label1"  => Nombre serie 1
//   "label2"  => Nombre serie 2
//   "titulo"  => Título de la gráfica
//   "archivo" => Ruta PNG de salida
//   "maxval"  => Máximo eje Y (0 = automático)
// Retorna: .T. si se generó correctamente
// ----------------------------------------------------------
FUNCTION AURA_ChartGroupedBar( hOpts )
    LOCAL cSvg
    LOCAL lExito

    cSvg   := _SVG_GroupedBar( hOpts )
    lExito := SVG_TO_PNG( cSvg, hOpts[ "archivo" ] )

RETURN lExito

// ----------------------------------------------------------
// FUNCIÓN INTERNA: Genera el SVG de barras agrupadas
// ----------------------------------------------------------
STATIC FUNCTION _SVG_GroupedBar( hOpts )
    LOCAL aData1  := hOpts[ "data1"  ]
    LOCAL aData2  := hOpts[ "data2"  ]
    LOCAL aLabels := hOpts[ "labels" ]
    LOCAL cLabel1 := hOpts[ "label1" ]
    LOCAL cLabel2 := hOpts[ "label2" ]
    LOCAL cTitulo := hOpts[ "titulo" ]
    LOCAL nMaxVal := hOpts[ "maxval" ]

    LOCAL cSvg
    LOCAL nW      := 900
    LOCAL nH      := 500
    LOCAL nPadL   := 80
    LOCAL nPadR   := 40
    LOCAL nPadT   := 80
    LOCAL nPadB   := 60
    LOCAL nPlotW  := nW - nPadL - nPadR
    LOCAL nPlotH  := nH - nPadT - nPadB
    LOCAL nMinVal := 0
    LOCAL nRangeY
    LOCAL nGroups := LEN( aLabels )
    LOCAL nGroupW := nPlotW / nGroups
    LOCAL nBarW   := nGroupW * 0.30
    LOCAL nGap    := nGroupW * 0.05

    LOCAL cColor1    := "#E8622A"
    LOCAL cColor2    := "#1F3F6E"
    LOCAL cColorGrid := "#E0E0E0"
    LOCAL cColorAxis := "#666666"
    LOCAL cColorLbl  := "#333333"

    LOCAL i, nX, nY1, nY2, nBarH1, nBarH2, nCenterX
    LOCAL cPoints1 := ""
    LOCAL cPoints2 := ""
    LOCAL nYtick, nYpos, cLabelVal
    LOCAL sW, sH, sPadL, sPadLm8, sPlotW, sAxisY
    LOCAL sCX, sX, sY1, sY2, sBH1, sBH2, sBW

    IF nMaxVal == NIL .OR. nMaxVal == 0
        nMaxVal := 0
        FOR i := 1 TO nGroups
            nMaxVal := MAX( nMaxVal, aData1[i] )
            nMaxVal := MAX( nMaxVal, aData2[i] )
        NEXT
        nMaxVal := ( INT( nMaxVal / 100 ) + 1 ) * 100
    ENDIF

    nRangeY := nMaxVal - nMinVal

    // Precalcular strings fijos
    sW    := ALLTRIM(STR(nW))
    sH    := ALLTRIM(STR(nH))
    sPadL := ALLTRIM(STR(nPadL))

    cSvg := [<svg width="] + sW + [" height="] + sH + [" xmlns="http://www.w3.org/2000/svg" font-family="Arial,sans-serif">]
    cSvg += [<rect width="100%" height="100%" fill="#FFFFFF"/>]

    // Título
    cSvg += [<text x="] + sPadL + [" y="28" font-size="16" font-weight="bold" fill="] + cColorLbl + [">] + cTitulo + [</text>]

    // Leyenda serie 1
    cSvg += [<rect x="] + sPadL + [" y="44" width="14" height="14" fill="] + cColor1 + ["/>]
    cSvg += [<text x="] + ALLTRIM(STR(nPadL+18)) + [" y="56" font-size="12" fill="] + cColorLbl + [">] + cLabel1 + [</text>]

    // Leyenda serie 2
    cSvg += [<rect x="] + ALLTRIM(STR(nPadL+70)) + [" y="44" width="14" height="14" fill="] + cColor2 + ["/>]
    cSvg += [<text x="] + ALLTRIM(STR(nPadL+88)) + [" y="56" font-size="12" fill="] + cColorLbl + [">] + cLabel2 + [</text>]

    // Grilla horizontal + etiquetas eje Y
    FOR nYtick := 0 TO nMaxVal STEP INT( nMaxVal / 7 )
        nYpos  := nPadT + nPlotH - INT( nYtick / nRangeY * nPlotH )
        sPlotW := ALLTRIM(STR(nPadL+nPlotW))
        sPadLm8 := ALLTRIM(STR(nPadL-8))
        cSvg += [<line x1="] + sPadL + [" y1="] + ALLTRIM(STR(nYpos)) + [" x2="] + sPlotW + [" y2="] + ALLTRIM(STR(nYpos)) + [" stroke="] + cColorGrid + [" stroke-width="1"/>]
        cSvg += [<text x="] + sPadLm8 + [" y="] + ALLTRIM(STR(nYpos+4)) + [" font-size="11" fill="] + cColorAxis + [" text-anchor="end">$] + ALLTRIM(STR(nYtick)) + [ mil</text>]
    NEXT

    // Eje X base
    sAxisY := ALLTRIM(STR(nPadT+nPlotH))
    cSvg += [<line x1="] + sPadL + [" y1="] + sAxisY + [" x2="] + ALLTRIM(STR(nPadL+nPlotW)) + [" y2="] + sAxisY + [" stroke="] + cColorAxis + [" stroke-width="1"/>]

    // Barras + etiquetas + puntos de línea
    FOR i := 1 TO nGroups
        nCenterX := nPadL + INT( (i-1) * nGroupW + nGroupW / 2 )
        sCX      := ALLTRIM(STR(nCenterX))
        sBW      := ALLTRIM(STR(INT(nBarW)))

        // Serie 1
        nX     := INT( nCenterX - nBarW - nGap / 2 )
        nBarH1 := INT( aData1[i] / nRangeY * nPlotH )
        nY1    := nPadT + nPlotH - nBarH1
        sX     := ALLTRIM(STR(nX))
        sY1    := ALLTRIM(STR(nY1))
        sBH1   := ALLTRIM(STR(nBarH1))
        cSvg += [<rect x="] + sX + [" y="] + sY1 + [" width="] + sBW + [" height="] + sBH1 + [" fill="] + cColor1 + [" rx="2"/>]
        cLabelVal := "$" + ALLTRIM(STR(aData1[i])) + " mil"
        cSvg += [<text x="] + ALLTRIM(STR(INT(nX+nBarW/2))) + [" y="] + ALLTRIM(STR(nY1-4)) + [" font-size="10" fill="] + cColor1 + [" text-anchor="middle">] + cLabelVal + [</text>]

        // Serie 2
        nX     := INT( nCenterX + nGap / 2 )
        nBarH2 := INT( aData2[i] / nRangeY * nPlotH )
        nY2    := nPadT + nPlotH - nBarH2
        sX     := ALLTRIM(STR(nX))
        sY2    := ALLTRIM(STR(nY2))
        sBH2   := ALLTRIM(STR(nBarH2))
        cSvg += [<rect x="] + sX + [" y="] + sY2 + [" width="] + sBW + [" height="] + sBH2 + [" fill="] + cColor2 + [" rx="2"/>]
        cLabelVal := "$" + ALLTRIM(STR(aData2[i])) + " mil"
        cSvg += [<text x="] + ALLTRIM(STR(INT(nX+nBarW/2))) + [" y="] + ALLTRIM(STR(nY2-4)) + [" font-size="10" fill="] + cColor2 + [" text-anchor="middle">] + cLabelVal + [</text>]

        // Etiqueta eje X
        cSvg += [<text x="] + sCX + [" y="] + ALLTRIM(STR(nPadT+nPlotH+20)) + [" font-size="12" fill="] + cColorAxis + [" text-anchor="middle">] + aLabels[i] + [</text>]

        // Puntos línea serie 1
        IF LEN(cPoints1) > 0 ; cPoints1 += " " ; ENDIF
        cPoints1 += ALLTRIM(STR(INT(nCenterX-nBarW/2-nGap/2))) + "," + ALLTRIM(STR(nY1))

        // Puntos línea serie 2
        IF LEN(cPoints2) > 0 ; cPoints2 += " " ; ENDIF
        cPoints2 += ALLTRIM(STR(INT(nCenterX+nBarW/2+nGap/2))) + "," + ALLTRIM(STR(nY2))
    NEXT

    // Líneas de tendencia
    cSvg += [<polyline points="] + cPoints1 + [" fill="none" stroke="] + cColor1 + [" stroke-width="2.5" stroke-linejoin="round"/>]
    cSvg += [<polyline points="] + cPoints2 + [" fill="none" stroke="] + cColor2 + [" stroke-width="2.5" stroke-linejoin="round"/>]

    // Círculos sobre líneas
    FOR i := 1 TO nGroups
        nCenterX := nPadL + INT( (i-1)*nGroupW + nGroupW/2 )
        nY1 := nPadT + nPlotH - INT( aData1[i] / nRangeY * nPlotH )
        nY2 := nPadT + nPlotH - INT( aData2[i] / nRangeY * nPlotH )
        cSvg += [<circle cx="] + ALLTRIM(STR(INT(nCenterX-nBarW/2-nGap/2))) + [" cy="] + ALLTRIM(STR(nY1)) + [" r="4" fill="] + cColor1 + ["/>]
        cSvg += [<circle cx="] + ALLTRIM(STR(INT(nCenterX+nBarW/2+nGap/2))) + [" cy="] + ALLTRIM(STR(nY2)) + [" r="4" fill="] + cColor2 + ["/>]
    NEXT

    cSvg += [</svg>]

RETURN cSvg

// ----------------------------------------------------------
// WRAPPER C++ - Motor de renderizado SVG -> PNG
// ----------------------------------------------------------
#pragma BEGINDUMP

#define LUNASVG_BUILD_STATIC
#include "hbapi.h"
#include <lunasvg.h>
#include <string>

#ifdef __cplusplus
extern "C" {
#endif

HB_FUNC( SVG_TO_PNG )
{
    const char * szSvgText    = hb_parc( 1 );
    const char * szOutputFile = hb_parc( 2 );

    if( szSvgText && szOutputFile )
    {
        auto document = lunasvg::Document::loadFromData( std::string( szSvgText ) );
        if( document )
        {
            auto bitmap = document->renderToBitmap();
            if( bitmap.valid() )
            {
                hb_retl( bitmap.writeToPng( std::string( szOutputFile ) ) );
                return;
            }
        }
    }
    hb_retl( false );
}

#ifdef __cplusplus
}
#endif

#pragma ENDDUMP