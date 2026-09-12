import 'package:excel/excel.dart';

/// Estilos y formatos de celdas reutilizables para la exportación en Excel
class ExcelStyles {
  static final CellStyle percentStyle = CellStyle(
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    numberFormat: NumFormat.standard_9, // Formato % nativo
  );

  static final CellStyle grayHeaderStyle = CellStyle(
    backgroundColorHex: ExcelColor.fromHexString("#C0C0C0"),
    bold: true,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    textWrapping: TextWrapping.WrapText,
  );

  static final CellStyle greenTitleStyle = CellStyle(
    fontFamily: "Arial",
    fontSize: 22,
    bold: true,
    fontColorHex: ExcelColor.fromHexString("#00B050"),
    backgroundColorHex: ExcelColor.fromHexString("#C0C0C0"),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  static final CellStyle docControlHeaderStyle = CellStyle(
    fontFamily: "Arial",
    fontSize: 12,
    bold: false,
    backgroundColorHex: ExcelColor.fromHexString("#C0C0C0"),
    horizontalAlign: HorizontalAlign.Left,
    verticalAlign: VerticalAlign.Center,
  );

  static final CellStyle docControlValueStyle = CellStyle(
    fontFamily: "Arial",
    fontSize: 18,
    bold: true,
    fontColorHex: ExcelColor.fromHexString("#00B050"),
    backgroundColorHex: ExcelColor.fromHexString("#C0C0C0"),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  static final CellStyle formLabelStyle = CellStyle(
    fontFamily: "Calibri",
    fontSize: 11,
    bold: true,
    backgroundColorHex: ExcelColor.fromHexString("#F2F2F2"),
    horizontalAlign: HorizontalAlign.Left,
    verticalAlign: VerticalAlign.Center,
  );

  static final CellStyle formInputStyle = CellStyle(
    fontFamily: "Calibri",
    fontSize: 11,
    bold: false,
    horizontalAlign: HorizontalAlign.Left,
    verticalAlign: VerticalAlign.Center,
  );

  static final CellStyle blueHeaderStyleTable = CellStyle(
    backgroundColorHex: ExcelColor.fromHexString("#8EA9DB"),
    bold: true,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    textWrapping: TextWrapping.WrapText,
  );

  static final CellStyle grayHeaderStyleTable = CellStyle(
    backgroundColorHex: ExcelColor.fromHexString("#BFBFBF"),
    bold: true,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    textWrapping: TextWrapping.WrapText,
  );

  static final CellStyle ncHeaderStyleTable = CellStyle(
    backgroundColorHex: ExcelColor.fromHexString("#FCE4D6"),
    bold: true,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    textWrapping: TextWrapping.WrapText,
  );

  static final CellStyle stdTimeHeaderStyleTable = CellStyle(
    backgroundColorHex: ExcelColor.fromHexString("#E2EFDA"),
    bold: true,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    textWrapping: TextWrapping.WrapText,
  );

  static final CellStyle lightBlueDataStyle = CellStyle(
    backgroundColorHex: ExcelColor.fromHexString("#D9E1F2"),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    textWrapping: TextWrapping.WrapText,
  );

  static final CellStyle whiteDataStyle = CellStyle(
    backgroundColorHex: ExcelColor.fromHexString("#FFFFFF"),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    textWrapping: TextWrapping.WrapText,
  );

  static final CellStyle twoDecimalsWhiteStyle = CellStyle(
    backgroundColorHex: ExcelColor.fromHexString("#FFFFFF"),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    numberFormat: NumFormat.custom(formatCode: "0.00"),
  );

  static final CellStyle ncDataStyle = CellStyle(
    backgroundColorHex: ExcelColor.fromHexString("#FCE4D6"),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  static final CellStyle grayDataTwoDecimalsStyle = CellStyle(
    backgroundColorHex: ExcelColor.fromHexString("#BFBFBF"),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    numberFormat: NumFormat.custom(formatCode: "0.00"),
  );

  static final CellStyle greenDataTwoDecimalsStyle = CellStyle(
    backgroundColorHex: ExcelColor.fromHexString("#E2EFDA"),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    numberFormat: NumFormat.custom(formatCode: "0.00"),
  );

  static final CellStyle processSummaryGrayStyle = CellStyle(
    backgroundColorHex: ExcelColor.fromHexString("#D9D9D9"),
    bold: true,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  static final CellStyle greenSummaryHeaderStyle = CellStyle(
    backgroundColorHex: ExcelColor.fromHexString("#C6EFCE"),
    bold: true,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  static final CellStyle greenKpiLabelStyle = CellStyle(
    backgroundColorHex: ExcelColor.fromHexString("#A9D08E"),
    bold: true,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  static final CellStyle greenKpiValueStyle = CellStyle(
    backgroundColorHex: ExcelColor.fromHexString("#FFFFFF"),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    numberFormat: NumFormat.custom(formatCode: "0.00"),
  );

  static final CellStyle lightBluePercentStyle = CellStyle(
    backgroundColorHex: ExcelColor.fromHexString("#D9E1F2"),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    numberFormat: NumFormat.standard_9,
  );

  static final CellStyle jabilLogoStyle = CellStyle(
    backgroundColorHex: ExcelColor.fromHexString("#C0C0C0"),
    bold: true,
    fontSize: 22,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );
}
