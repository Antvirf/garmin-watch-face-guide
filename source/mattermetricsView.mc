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

    // Get corresponding string value for date field, given app setting
    private function getDateInfoAsString(dc as Dc, option as Number) as String {
        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var longInfo = Gregorian.info(Time.now(), Time.FORMAT_LONG);
	    switch (option){
	    	case 0: // Day of month, number
			   	return Lang.format("$1$", [info.day]);
	    	case 1: // Month of year, number
                return Lang.format("$1$", [info.month]);
	    	case 2: // Month of year, text
                return Lang.format("$1$", [longInfo.month]);
	    	case 3: // Day of week, text
                return Lang.format("$1$", [longInfo.day_of_week]);
	    }
    }


    // Get UTC timestamp
    private function getUTCInfoAsString(dc as Dc) as String {
        var info = Gregorian.utcInfo(Time.now(), Time.FORMAT_SHORT);
			  return Lang.format("$1$", [info.value]);
    }

    // Get corresponding start time value, given app setting
    private function getStartTimeValue(dc as Dc, option as Number) as Array<Number>{
        switch (option){
            case 0:
                return [6,0];
            case 1:
                return [6,30];
            case 2:
                return [7,0];
            case 3:
                return [7,30];
            case 4:
                return [8,0];
            case 5:
                return [8,30];
            case 6:
                return [9,0];
            case 7:
                return [9,30];
            case 8:
                return [10,0];
            case 9:
                return [10,30];
            case 10:
                return [11,0];
            case 11:
                return [11,30];
            case 12:
                return [12,0];
            case 13:
                return [12,30];
        }
    }

    // Get corresponding end time value, given app setting
    private function getEndTimeValue(dc as Dc, option as Number) as Array<Number>{
        switch (option){
            case 0:
                return [13,0];
            case 1:
                return [13,30];
            case 2:
                return [14,0];
            case 3:
                return [14,30];
            case 4:
                return [15,0];
            case 5:
                return [15,30];
            case 6:
                return [16,0];
            case 7:
                return [16,30];
            case 8:
                return [17,0];
            case 9:
                return [17,30];
            case 10:
                return [18,0];
            case 11:
                return [18,30];
            case 12:
                return [19,0];
            case 13:
                return [19,30];
            case 14:
                return [20,0];
            case 15:
                return [20,30];
            case 16:
                return [21,0];
            case 17:
                return [21,30];
            case 18:
                return [22,0];
            case 19:
                return [22,30];
        }
    }

    // Convert timevalue arrays into a nicely formatted string
    private function prettifyTimeArray(input as Array<Number>) as String {
        if (getApp().getProperty("UseMilitaryFormat")) {
            return input[0].format("%02d") + input[1].format("%02d");
        } else {
            return input[0].format("%02d") + ":" + input[1].format("%02d");
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
        var utcHours = clockTime.hour - clockTime.timeZoneOffset/3600;
        if (!System.getDeviceSettings().is24Hour) {
            if (hours > 12) {
                hours = hours - 12;
            }
            if (utcHours > 12) {
                utcHours = utcHours - 12;
            }
        } else {
            if (getApp().getProperty("UseMilitaryFormat")) {
                timeFormat = "$1$$2$";
                hours = hours.format("%02d");
                utcHours = utcHours.format("%02d");
            }
        }

        // Draw and update time and date
        var timeString = Lang.format(timeFormat, [hours, clockTime.min.format("%02d")]);
        var timeView = View.findDrawableById("TimeLabel") as Text;
        timeView.setColor(0xFFFFFF);
        timeView.setText(timeString);

        // Draw date
        var dateFirstPart = getDateInfoAsString(dc, Application.getApp().Properties.getValue("DateInfoFirst"));
        var dateSecondPart = getDateInfoAsString(dc, Application.getApp().Properties.getValue("DateInfoSecond"));
        var dateString = dateFirstPart + "-" + dateSecondPart;

        var dateView = View.findDrawableById("DateLabel") as Text;
        dateView.setColor(0xFFFFFF);
        dateView.setText(dateString);

        // Draw UTC timestamp
        if (Application.getApp().getProperty("DrawDevTools")) {
          var utcTimeString = Lang.format(timeFormat, [utcHours, clockTime.min.format("%02d")]);
          var utcView = View.findDrawableById("UTCTime") as Text;
          utcView.setColor(0xFFFFFF);
          utcView.setText(utcTimeString);

          var utcLabel = View.findDrawableById("UTCTimestamp") as Text;
          utcLabel.setColor(Graphics.COLOR_DK_GRAY);
          var timestamp = new Time.Moment(Time.now().value());
          var tsPrint = Lang.format("$1$", [timestamp.value()]);
          utcLabel.setText(tsPrint);
        }

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
        var timeStart = getStartTimeValue(dc, Application.getApp().Properties.getValue("TimeGaugeStartValue"));
        var timeEnd = getEndTimeValue(dc, Application.getApp().Properties.getValue("TimeGaugeEndValue"));
        var prettyStartTime = prettifyTimeArray(timeStart);
        var prettyEndTime = prettifyTimeArray(timeEnd);

        var startHour = timeStart[0]; //6;
        var startMin =  timeStart[1]; //15;
        var endHour = timeEnd[0]; //18;
        var endMin = timeEnd[1]; //30;

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
        drawGauge(dc, 10, 4, 1, 0.0, timeDiffTotal.toFloat(), timeDiffCurrent.toFloat(), [prettyStartTime, prettyEndTime, ""]);
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
