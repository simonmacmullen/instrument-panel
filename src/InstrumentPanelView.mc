// -*- mode: Javascript;-*-

using Toybox.Graphics;
using Toybox.Position;
using Toybox.Sensor;
using Toybox.Math;
using Toybox.System;
using Toybox.WatchUi as Ui;
using Toybox.Application as App;

enum {
    MODE_COMPASS,
    MODE_ALTITUDE,
    MODE_TIME,
    MODE_POSITION,
    MODE_LAST
}

class InstrumentPanelView extends Ui.View {
    var speed = null;
    var heading = null;
    var position = null;
    var altitude = null;
    var temperature = null;
    var posQualities = ["None", "Last", "Poor", "OK", "Good"];
    var posQuality = posQualities[0];

    var speedMax = 0;
    var speedRange = 20;
    var speedRanges = [20, 50, 100, 200, 500, 1000, 2000];

    var speedMetric = System.getDeviceSettings().paceUnits == System.UNIT_METRIC;
    var elevMetric = System.getDeviceSettings().elevationUnits == System.UNIT_METRIC;
    var tempMetric = System.getDeviceSettings().temperatureUnits == System.UNIT_METRIC;
    var time24h = System.getDeviceSettings().is24Hour;

    var mode = MODE_COMPASS;

    function cycleView() {
        mode++;
        if (mode == MODE_LAST) {
            mode = MODE_COMPASS;
        }
        Ui.requestUpdate();
    }


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

        drawSpeed(dc, 109, 109, 96);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        if (mode == MODE_COMPASS) {
            if (heading != null) {
                drawCompass(dc, 109, 170, 25);
            }
        }
        else if (mode == MODE_ALTITUDE) {
            var altitudeTxt = "";
            if (altitude != null) {
                altitudeTxt = altitude + (elevMetric ? "m" : "ft");
            }
            dc.drawText(109, 155, Graphics.FONT_TINY,
                        altitudeTxt, Graphics.TEXT_JUSTIFY_CENTER);
        }
        else if (mode == MODE_TIME) {
            var timeTxt = fmtTime(System.getClockTime());
            // TODO figure out why temperature doesn't work
            // if (temperature != null) {
            //     timeTxt += " " + temperature + (tempMetric ? "C" : "F");
            // }
            dc.drawText(109, 155, Graphics.FONT_TINY,
                        timeTxt, Graphics.TEXT_JUSTIFY_CENTER);
        }
        else if (mode == MODE_POSITION) {
            var positionTxt = "";
            var positionTxt2 = "";
            if (position != null) {
                positionTxt = position.toGeoString(Position.GEO_DEG);
                positionTxt2 = positionTxt.substring(11, 20);
                positionTxt = positionTxt.substring(0, 9);
            }
            dc.drawText(109, 145, Graphics.FONT_TINY,
                        positionTxt, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(109, 165, Graphics.FONT_TINY,
                        positionTxt2, Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(109, 185, Graphics.FONT_XTINY,
                        posQuality, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    function drawSpeed(dc, cX, cY, radius) {
        var startAngle = Math.PI - 1;
        var endAngle = -Math.PI + 1;
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        drawArc(dc, cX, cY, startAngle, endAngle, radius - 1, radius);
        drawTicks(dc, cX, cY, startAngle, endAngle, radius - 15, radius, 11);
        drawTicks(dc, cX, cY, startAngle, endAngle, radius - 5, radius, 51);
        
        drawTextPolar(dc, cX, cY, startAngle + 0.2, radius - 5,
                      Graphics.FONT_XTINY, "0");
        drawTextPolar(dc, cX, cY, endAngle - 0.2, radius - 5,
                      Graphics.FONT_XTINY, "" + speedRange);

        dc.drawText(cX, cY - 14, Graphics.FONT_XTINY,
                    speedMetric ? "km/h" : "mph", Graphics.TEXT_JUSTIFY_CENTER);

        var speedTxt = "---";
        
        if (speed != null) {
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
            drawArc(dc, cX, cY, startAngle,
                    interp(startAngle, endAngle, speed, speedRange),
                    radius - 1, radius + 9);
            speedTxt = "" + speed;
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cX, cY * 0.35, Graphics.FONT_NUMBER_MEDIUM,
                    speedTxt, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function drawCompass(dc, cX, cY, radius) {
        var f = Graphics.FONT_XTINY;
        drawTextPolar(dc, cX, cY, heading,               radius, f, "N");
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        drawTextPolar(dc, cX, cY, heading - Math.PI / 2, radius, f, "E");
        drawTextPolar(dc, cX, cY, heading + Math.PI / 2, radius, f, "W");
        drawTextPolar(dc, cX, cY, heading + Math.PI,     radius, f, "S");
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        var startAngle = heading + 0.5;
        var endAngle = heading + Math.PI / 2 - 0.5;
        for (var i = 0; i < 4; i++) {
            drawArc(dc, cX, cY,
                    startAngle + i * Math.PI / 2,
                    endAngle + i * Math.PI / 2,
                    radius, radius + 5);
        }
    }

    function fmtTime(time) {
        var hour = time.hour;
        var min = time.min.toString();
        // TODO remove when printf works on device
        if (min.length() == 1) {
            min = "0" + min;
        }
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

    function drawTextPolar(dc, centerX, centerY, angle, distance, font, text) {
        var xy = pol2Cart(centerX, centerY, angle, distance);
        dc.drawText(xy[0], xy[1], font, text,
                    Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function drawArc(dc, centerX, centerY, startAngle, endAngle,
                     startDist, endDist) {
        var n = 20;
        var poly = new[n * 2];

        for (var i = 0; i < n; i++) {
            var angle = interp(startAngle, endAngle, i, n - 1);
            poly[i] = pol2Cart(centerX, centerY, angle, startDist);
            poly[n * 2 - i - 1] = pol2Cart(centerX, centerY, angle, endDist);
        }

        dc.fillPolygon(poly);
    }

    function drawTicks(dc, centerX, centerY, startAngle, endAngle,
                       startDist, endDist, count) {
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
            return null;
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
        
        position = info.position;
        posQuality = posQualities[info.accuracy];

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

class InstrumentPanelDelegate extends Ui.InputDelegate {
    function onKey(evt) {
        if (evt.getKey() == Ui.KEY_ENTER) {
            widget.cycleView();
            return true;
        }
        return false;
    }
}

var widget;

class InstrumentPanelApp extends App.AppBase {
    function onStart() {
    }

    function onStop() {
    }

    function getInitialView() {
        widget = new InstrumentPanelView();
        return [widget, new InstrumentPanelDelegate()];
    }
}
