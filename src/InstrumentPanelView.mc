// -*- mode: Javascript;-*-

using Toybox.Graphics;
using Toybox.Position;
using Toybox.Sensor;
using Toybox.Math;
using Toybox.System;
using Toybox.WatchUi as Ui;
using Toybox.Application as App;

class InstrumentPanelView extends Ui.View {
    var speed = null;
    var heading = null;
    var altitude = null;
    var temperature = null;

    var speedMax = 0;
    var speedRange = 20;
    var speedRanges = [20, 50, 100, 200, 500, 1000, 2000];

    var speedMetric = System.getDeviceSettings().paceUnits == System.UNIT_METRIC;
    var elevMetric = System.getDeviceSettings().elevationUnits == System.UNIT_METRIC;
    var tempMetric = System.getDeviceSettings().temperatureUnits == System.UNIT_METRIC;
    var time24h = System.getDeviceSettings().is24Hour;

    //! Load your resources here
    function onLayout(dc) {
    }

    //! Restore the state of the app and prepare the view to be shown
    function onShow() {
        Sensor.setEnabledSensors( [Sensor.SENSOR_TEMPERATURE] );
        Sensor.enableSensorEvents( method(:onSensor) );
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS,
                                      method(:onLocation));
    }

    //! Called when this View is removed from the screen. Save the
    //! state of your app here.
    function onHide() {
    }

    //! Update the view
    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        
        var width = dc.getWidth();
        var height = dc.getHeight();

        if (heading != null) {
            var f = Graphics.FONT_MEDIUM;
            drawTextPolar(dc, heading,               95, f, "N");
            drawTextPolar(dc, heading - Math.PI / 2, 95, f, "E");
            drawTextPolar(dc, heading + Math.PI / 2, 95, f, "W");
            drawTextPolar(dc, heading + Math.PI,     95, f, "S");
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            var startAngle = heading + 0.25;
            var endAngle = heading + Math.PI / 2 - 0.25;
            for (var i = 0; i < 4; i++) {
                drawArc(dc,
                        startAngle + i * Math.PI / 2,
                        endAngle + i * Math.PI / 2,
                        90, 100);
            }
        }

        var startAngle = Math.PI - 1;
        var endAngle = -Math.PI + 1;
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        drawArc(dc, startAngle, endAngle, 79, 80);
        drawTicks(dc, startAngle, endAngle, 65, 80, 11);
        drawTicks(dc, startAngle, endAngle, 75, 80, 51);
        
        drawTextPolar(dc, startAngle + 0.2, 70, Graphics.FONT_XTINY, "0");
        drawTextPolar(dc, endAngle - 0.2, 70, Graphics.FONT_XTINY,
                      "" + speedRange);

        dc.drawText(109, 105, Graphics.FONT_XTINY,
                    speedMetric ? "km/h" : "mph", Graphics.TEXT_JUSTIFY_CENTER);

        var speedTxt = "---";
        
        if (speed != null) {
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
            drawArc(dc,
                    startAngle,
                    interp(startAngle, endAngle, speed, speedRange),
                    70, 80);
            speedTxt = "" + speed;
        }
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(109, 50, Graphics.FONT_NUMBER_MEDIUM,
                    speedTxt, Graphics.TEXT_JUSTIFY_CENTER);

        var timeTxt = fmtTime(System.getClockTime());
        if (temperature != null) {
            timeTxt += " " + temperature + (tempMetric ? "C" : "F");
        }
        dc.drawText(109, 130, Graphics.FONT_XTINY,
                    timeTxt, Graphics.TEXT_JUSTIFY_CENTER);

        var altitudeTxt = "---";
        if (altitude != null) {
            altitudeTxt = altitude + (elevMetric ? "m" : "ft");
        }
        dc.drawText(109, 155, Graphics.FONT_XTINY,
                    altitudeTxt, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function fmtTime(time) {
        var hour = time.hour;
        var min = time.min.format("%2d");
        if (time24h) {
            return hour + ":" + min;
        }
        else {
            var ampm = (hour > 11) ? "pm" : "am";
            hour = (hour > 12) ? hour - 12 : hour;
            if (hour == 0) {
                hour = 12;
            }
            return hour + ":" + min + ampm;
        }
    }

    function drawTextPolar(dc, angle, distance, font, text) {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;

        var xy = pol2Cart(centerX, centerY, angle, distance);
        dc.drawText(xy[0], xy[1], font, text,
                    Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function drawArc(dc, startAngle, endAngle, startDist, endDist) {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;
        var n = 20;
        var poly = new[n * 2];

        for (var i = 0; i < n; i++) {
            var angle = interp(startAngle, endAngle, i, n - 1);
            poly[i] = pol2Cart(centerX, centerY, angle, startDist);
            poly[n * 2 - i - 1] = pol2Cart(centerX, centerY, angle, endDist);
        }

        dc.fillPolygon(poly);
    }

    function drawTicks(dc, startAngle, endAngle, startDist, endDist, count) {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;

        for (var i = 0; i < count; i++) {
            var angle = interp(startAngle, endAngle, i, count - 1);
            var xy1 = pol2Cart(centerX, centerY, angle, startDist);
            var xy2 = pol2Cart(centerX, centerY, angle, endDist);
            dc.drawLine(xy1[0], xy1[1], xy2[0], xy2[1]);
        }
    }

    function interp(min, max, numerator, denominator) {
        return min + (max - min) * numerator / denominator;
    }

    function pol2Cart(centerX, centerY, angle, distance) {
        var x = distance * Math.sin(angle);
        var y = distance * Math.cos(angle);
        return [centerX - x, centerY - y];
    }

    function fmtSpeed(m) {
        if (m == null) {
            return 55;//null;
        }
        if (speedMetric) {
            return (m * 3.6).toNumber();
        }
        else {
            return (m * 3.6 * 1.609).toNumber();
        }
    }

    function fmtAltitude(m) {
        if (m == null) {
            return null;
        }
        if (elevMetric) {
            return m.toNumber();
        }
        else {
            return (m * 3.280).toNumber();
        }
    }

    function fmtTemp(m) {
        if (m == null) {
            return null;
        }
        if (tempMetric) {
            return m.toNumber();
        }
        else {
            return (m * 9 / 5 + 32).toNumber();
        }
    }

    function onLocation(info) {
        // Always prefer compass heading
        if (heading == null) {
            heading = info.heading;
        }

        speed = fmtSpeed(info.speed);
        if (speed != null and speed > speedMax) {
            speedMax = speed;
            if (speedMax > speedRange) {
                for (var i = 0; i < speedRanges.size(); i++) {
                    if (speedMax < speedRanges[i]) {
                        speedRange = speedRanges[i];
                        break;
                    }
                }
            }
        }

        altitude = fmtAltitude(info.altitude);
        Ui.requestUpdate();
    }

    function onSensor(info) {
        heading = info.heading;
        altitude = fmtAltitude(info.altitude);
        temperature = fmtTemp(info.temperature);
        Ui.requestUpdate();
    }
}

class InstrumentPanelApp extends App.AppBase {
    function onStart() {
    }

    function onStop() {
    }

    function getInitialView() {
        return [new InstrumentPanelView()];
    }
}
