/*@get(barChart slider)*/
barChart~animated = .false
.local~monthlyTurnover = .my.app~dbh~getMonthlyTurnover
maxMonths = .my.app~dbh~getDistinctMonths

sliderHandler = .SliderHandler~new(slider, barChart, maxMonths)

::CLASS SliderHandler
::METHOD slider ATTRIBUTE
::METHOD barChart ATTRIBUTE
::METHOD INIT
  EXPOSE slider barChart XYChart XYChartData XYChartSeries
  USE ARG slider, barChart, maxMonths
  listener = BsfCreateRexxProxy(self,,"javafx.beans.value.ChangeListener")
  slider~valueProperty~addListener(listener)
  XYChart = bsf.loadClass("javafx.scene.chart.XYChart")
  XYChartData = bsf.import("javafx.scene.chart.XYChart$Data")
  XYChartSeries = bsf.import("javafx.scene.chart.XYChart$Series")
  IF maxMonths > 12 THEN monthToDisplay = 12
  ELSE monthToDisplay = maxMonths
  slider~setMax(maxMonths)
  slider~setValue(monthToDisplay)

::METHOD changed
  EXPOSE slider barChart XYChart XYChartData XYChartSeries
  monthToDisplay = format(slider~getValue,,0)
  maxMonths = slider~getMax
  dataSeries1 = XYChartSeries~new
  DO i=maxMonths-monthToDisplay+1 TO maxMonths
    date = .monthlyTurnover['dates'][i]
    rev = box("float", .monthlyTurnover['revenues'][i])
    dataSeries1~getData~add(XYChartData~new(date, rev))
  END
  barChart~getData~clear
  barChart~getData~add(dataSeries1)

::REQUIRES "BSF.CLS"
::REQUIRES "DatabaseHandler.CLS"