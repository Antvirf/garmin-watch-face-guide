import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time.Gregorian;

class mattermetricsView extends WatchUi.WatchFace {

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Draw hashmarks on particular hour indices - adapted from https://github.com/Antvirf/spectrefenix
    private function drawHashMarksAndLabels(dc as Dc, hours as Array<Number>, labels as Array<String>, scale_to_fenix as Number) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();

        // Creating the scaler based on the Fenix on which this was developed
        var thickness = 9 * scale_to_fenix;
        
        var outerRad = width / 2;
        var innerRad = outerRad - 10 * scale_to_fenix;
        var textInnerRad = innerRad - 15 * scale_to_fenix;
        
        for (var i = 0; i < hours.size(); i += 1) {
            var angle = (hours[i]/360.0)*2*Math.PI+Math.PI/2.0;
            var sX = outerRad + innerRad * Math.cos(angle);
            var sY = outerRad + innerRad * Math.sin(angle);

            var eY_u = outerRad + (outerRad + 10*scale_to_fenix) * Math.sin(angle) + thickness * Math.cos(angle);
            var eX_u = outerRad + (outerRad + 10*scale_to_fenix) * Math.cos(angle) + thickness * Math.sin(angle);
            
            var eY_l = outerRad + (outerRad + 10*scale_to_fenix) * Math.sin(angle) - thickness * Math.cos(angle);
            var eX_l = outerRad + (outerRad + 10*scale_to_fenix) * Math.cos(angle) - thickness * Math.sin(angle);

            dc.fillPolygon([[sY, sX],[eY_u, eX_u],[eY_l, eX_l]]);

            var textY = outerRad + textInnerRad * Math.cos(angle);
            var textX = outerRad + textInnerRad * Math.sin(angle);
            dc.drawText(textX, textY, Graphics.FONT_XTINY, labels[i], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    // Draw gauge function
    private function drawGauge(
        dc as Dc,
        start_hour as Number,
        duration_hours as Number,
        direction as Number,
        start_val as Float,
        end_val as Float,
        cur_val as Float,
        labels as Array<String>
    ) as Void {
        // Compute scaler
        var scale_to_fenix = dc.getWidth().toFloat()/260;

        // Make sure nothing overruns or overflows
        if (cur_val>=end_val) {
            cur_val=end_val;
            // labels[2] = "";
        }
        if (cur_val<=start_val){
            cur_val=start_val;
        }
        
        // Convert hour indices to arc start and end values in degreees
        var arcStart = 90.0 - start_hour*30.0;
        var arcEnd;
        if (direction == 0) {
            arcEnd = arcStart + 30.0*duration_hours; // this represents the value of the arc ending, IF the value was at 100%
        } else {
            arcEnd = arcStart - 30.0*duration_hours;
        }

        // Compute arc lengths
        var arcLengthInDegrees = arcEnd - arcStart;

        // Adjust arc length in case it is too long
        if (arcLengthInDegrees > 180){
            if (direction == 1) {
                arcLengthInDegrees = arcLengthInDegrees-90;
            } else {
                arcLengthInDegrees = arcLengthInDegrees;
            }
        }

        // Computing the end point of the actual measurement arc
        var proportion = (cur_val-start_val)/(end_val-start_val);

        // Make sure proportion isn't 0.0
        if (proportion == 0){
            proportion = 0.01;
        } else if (proportion < 0){
            proportion = 0.01;
        }

        var arcEndActual = arcStart + proportion*arcLengthInDegrees;
        var arcCenter = (arcStart+arcEnd)/2;

        // Compute coordinates for arc - X, Y and radius - they are all the same for a circular watch
        var arcCenterX = dc.getWidth()/2;
        var arcCenterY = arcCenterX;
        var arcRadius = arcCenterX;

        // Drawing the measuring gauge in white
        dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_TRANSPARENT);
        var scaledThickness = 1 * scale_to_fenix;
        var scaledThicknessSecond = 4 * scale_to_fenix;
        for (var i = scaledThickness; i <= scaledThickness+scaledThicknessSecond; i += 1) {
            dc.drawArc(arcCenterX, arcCenterY, arcRadius-i, direction, arcStart, arcEndActual);
        }

        // Draw value label in the middle in white
        if (labels[2] != ""){
            var outerRad = dc.getWidth() / 2;
            var innerRad = outerRad - 10*scale_to_fenix;
            var textInnerRad = innerRad - 13*scale_to_fenix;
            var angle = arcCenter/360 * 2 * Math.PI + Math.PI/2;
            var textY = outerRad + textInnerRad * Math.cos(angle);
            var textX = outerRad + textInnerRad * Math.sin(angle);
            dc.drawText(textX, textY, Graphics.FONT_XTINY, labels[2], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // Switch to gray background colour
        // Draw the background arc
        dc.setColor(Graphics.COLOR_DK_GRAY,Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i <= scaledThickness; i += 1) {
            dc.drawArc(arcCenterX, arcCenterY, arcRadius-i, direction, arcStart, arcEnd);
        }

        // Draw start and end indicators and add labels
        drawHashMarksAndLabels(dc, [arcStart, arcEnd], [labels[0], labels[1]], 1);
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Get the current time and format it correctly
        var timeFormat = "$1$:$2$";
        var clockTime = System.getClockTime();
        var hours = clockTime.hour;
        if (!System.getDeviceSettings().is24Hour) {
            if (hours > 12) {
                hours = hours - 12;
            }
        } else {
            if (getApp().getProperty("UseMilitaryFormat")) {
                timeFormat = "$1$$2$";
                hours = hours.format("%02d");
            }
        }

        // Draw and update time and date
        var timeString = Lang.format(timeFormat, [hours, clockTime.min.format("%02d")]);
        var timeView = View.findDrawableById("TimeLabel") as Text;
        timeView.setColor(0xFFFFFF);
        timeView.setText(timeString);

        // Draw date
        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var dateString = Lang.format("$1$-$2$", [info.day, info.month]);
        var dateView = View.findDrawableById("DateLabel") as Text;
        dateView.setColor(0xFFFFFF);
        dateView.setText(dateString);

        // Call the parent onUpdate function to redraw the layout level
        View.onUpdate(dc);

        // Draw steps gauge against set target
        var steps = ActivityMonitor.getInfo().steps/1.0;
        if (steps == 0.0){
            steps=1;
        }
        var stepsgoal =  ActivityMonitor.getInfo().stepGoal/1.0;
        drawGauge(dc, 6, 2, 0, 0.0, stepsgoal, steps, ["0", (stepsgoal/1000.0).format("%.1f")+"k", (steps/1000.0).format("%.1f")+"k"]);

        // Draw battery gauge against 100%
        var myStats = System.getSystemStats();
        var bat = myStats.battery;
        var batStr = Lang.format( "$1$%", [ bat.format("%2d") ] );
        drawGauge(dc, 6, 2, 1, 0.0, 100.0, bat, ["0", "100%", batStr]);

        // Draw sunrise and sunset
        // Define start and end times
        var startHour = 6;
        var startMin =  15;
        var endHour = 18;
        var endMin = 30;

        // Compute total time difference in minutes
        var timeDiffTotal = (endHour-startHour)*60 +(endMin-startMin);

        // Compute diff from current time
        var timeDiffCurrent = (clockTime.hour - startHour)*60 + (clockTime.min - startMin);
        if (timeDiffCurrent>timeDiffTotal) {
            timeDiffCurrent = timeDiffTotal;
        } else if (timeDiffCurrent.toFloat()/timeDiffTotal.toFloat()<0.01){
            // If the value is too small, it will get rounded down, making arc start and end values being identical
            timeDiffCurrent = timeDiffTotal.toFloat()*0.011; 
        }

        //var timeAmount = clockTime.hour*100.0 + clockTime.min/1.0;
        drawGauge(dc, 10, 4, 1, 0.0, timeDiffTotal.toFloat(), timeDiffCurrent.toFloat(), ["0615", "1830", ""]);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
    }
}
