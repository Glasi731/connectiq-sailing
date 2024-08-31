using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Time as Time;
using Toybox.Math as Math;

class SailingView extends Ui.View {

    var session = null;
    var countDown = null;

    // Graphical
    var screenHeight;
    var screenWidth;
    var minDim;
    var maxDim;
    var sec;
    var min;

    // Strings
    var accuracyStr = "0";
    var headingStr = "-";
    var headingOnlyStr = "-";
    var speedStr = "-";
    var unitsOffset = 0;
    var countDownStr = "";

    // Data
    var speedFloat = 0.0;

    // Constants
    const SPEED_UNIT = "kts";

    // Device settings
    var deviceSettings;

    function initialize(countdown) {
        Sys.println("view : initialize");
        View.initialize();
        countDown = countdown.weak();

        // Get device information
        deviceSettings = System.getDeviceSettings();
    }

    function onLayout(dc) {
        Sys.println("view : onLayout");
        screenWidth = dc.getWidth();
        screenHeight = dc.getHeight();
        if(screenHeight < screenWidth){
            minDim = screenHeight;
            maxDim = screenWidth;
        }else{
            minDim = screenWidth;
            maxDim = screenHeight;
        }
    }

    function updateTimer() {
        var secLeft = countDown.get().secondsLeft();

        sec = secLeft % 60;
        min = secLeft / 60;

        //format
        if(min > 0) {
            countDownStr = min.format("%d") + ":" + sec.format("%02d");
        }else {
            countDownStr = sec.format("%d");
        }
    }

    //! Called when this View is brought to the foreground. Restore
    //! the state of this View and prepare it to be shown. This includes
    //! loading resources into memory.
    function onShow() {
        Sys.println("view : onShow");
    }

    //! Update the view
    function onUpdate(dc) {
        Sys.println("view : onUpdate");
        var now = Time.now();

        dc.setColor( Gfx.COLOR_TRANSPARENT, Gfx.COLOR_BLACK );
        dc.clear();
        dc.setColor( Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT );

        if (countDown.get().isTimerRunning()) {
            updateTimer();
            var polygon = buildProgress();

            dc.fillPolygon(polygon);
            dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT );

            var innerRadius = (minDim / 2) - ((minDim / 2) * 0.2);
            var outerRadius = innerRadius + 1;

            dc.fillCircle(screenWidth / 2, screenHeight / 2, innerRadius);
            dc.setColor( Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT );
            dc.drawCircle(screenWidth / 2, screenHeight / 2, outerRadius);
            dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT );
            dc.drawText( (screenWidth / 2), (screenHeight / 2) - (Gfx.getFontAscent(Gfx.FONT_NUMBER_THAI_HOT) / 2), Gfx.FONT_NUMBER_THAI_HOT, countDownStr, Gfx.TEXT_JUSTIFY_CENTER );

        } else if (countDown.get().isTimerComplete()) {
            dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_BLACK );
            dc.drawText( (screenWidth / 2), (screenHeight / 2) - (Gfx.getFontAscent(Gfx.FONT_LARGE) / 2), Gfx.FONT_LARGE, "START", Gfx.TEXT_JUSTIFY_CENTER );

        } else {

            if( accuracyStr.toNumber() < Position.QUALITY_USABLE ) {
                dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
                dc.drawText((screenWidth / 2), (screenHeight / 2) - Gfx.getFontAscent(Gfx.FONT_MEDIUM) - Gfx.getFontDescent(Gfx.FONT_MEDIUM), Gfx.FONT_MEDIUM, "Waiting for", Gfx.TEXT_JUSTIFY_CENTER);
                dc.drawText((screenWidth / 2), (screenHeight / 2), Gfx.FONT_MEDIUM, "GPS signal ("+accuracyStr+")", Gfx.TEXT_JUSTIFY_CENTER);

            } else {
                dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);

                var nowInfo = Time.Gregorian.info(now, Time.FORMAT_MEDIUM);
                var nowString = Lang.format("$1$:$2$:$3$",
                    [nowInfo.hour.format("%02d"), nowInfo.min.format("%02d"), nowInfo.sec.format("%02d")]);

                if (speedFloat > 10.0){
                    unitsOffset = 5;
                } else {
                    unitsOffset = 0;
                }
                if (self has :getSubscreen) {
                    var subscreen = getSubscreen();

                    // If we are on the instinct (but not crossover), change the display
                    if(deviceSettings.screenShape == System.SCREEN_SHAPE_SEMI_OCTAGON)
                    {
                        dc.drawText((screenWidth / 3), 40, Gfx.FONT_TINY , nowString, Gfx.TEXT_JUSTIFY_CENTER);
                        dc.drawText((screenWidth / 2), (screenHeight / 2), Gfx.FONT_NUMBER_THAI_HOT, speedStr, Gfx.TEXT_JUSTIFY_CENTER);
                        dc.drawText((3 * (screenWidth / 4)) + unitsOffset, (screenHeight / 2), Gfx.FONT_MEDIUM, SPEED_UNIT, Gfx.TEXT_JUSTIFY_LEFT);
                        dc.drawText((subscreen.x + (subscreen.width / 2) + 4), (subscreen.y + (subscreen.height/4)), Gfx.FONT_MEDIUM, headingOnlyStr, Gfx.TEXT_JUSTIFY_CENTER);
                    }
                } else {
                    dc.drawText((screenWidth / 2), 0, Gfx.FONT_TINY , nowString, Gfx.TEXT_JUSTIFY_CENTER);
                    dc.drawText((screenWidth / 2), Gfx.getFontAscent(Gfx.FONT_MEDIUM), Gfx.FONT_NUMBER_THAI_HOT, speedStr, Gfx.TEXT_JUSTIFY_CENTER);
                    dc.drawText((screenWidth / 2), Gfx.getFontAscent(Gfx.FONT_NUMBER_THAI_HOT) + Gfx.getFontAscent(Gfx.FONT_MEDIUM) + 40, Gfx.FONT_MEDIUM, headingStr, Gfx.TEXT_JUSTIFY_CENTER);
                }

                var raceStartTime = countDown.get().startTime();

                if(raceStartTime != null){
                    //print running timer
                    var raceTime = now.subtract(raceStartTime);
                    var raceTimeStr = secToStr(raceTime.value());
                    dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
                    dc.drawText((screenWidth / 2), Gfx.getFontHeight(Gfx.FONT_NUMBER_THAI_HOT) + Gfx.getFontDescent(Gfx.FONT_MEDIUM), Gfx.FONT_MEDIUM, raceTimeStr, Gfx.TEXT_JUSTIFY_CENTER);
                    dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
                }
            }
        }
    }

    function buildProgress() {

        var center_x = screenWidth / 2;
        var center_y = screenHeight / 2;
        var border_x = screenWidth;
        var border_y = screenHeight;

        var TWO_PI = Math.PI * 2;

        var progress = ( sec / 60.0);
        var angle = progress * TWO_PI;

        var cAngle = angle;

        angle  -= Math.PI / 2.0;

        var point = [ (center_x + maxDim * Math.cos(angle)), (center_x + maxDim * Math.sin(angle)) ];

        var polygon = [];

        if (countDown.get().isTimerComplete()) {
            polygon = [
                    [0, 0],
                    [border_x, 0],
                    [border_x, border_y],
                    [0, border_y]
            ];
        } else if (cAngle  < (Math.PI / 4.0))    {
            polygon = [
                    [center_x, center_y],
                    [center_x, 0],
                    point
            ];
        } else if (cAngle < (Math.PI / 2))    {
            polygon = [
                    [center_x, 109],
                    [center_x, 0],
                    [border_x, 0],
                    point
            ];
        } else if (cAngle < (Math.PI * 0.75))    {
            polygon = [
                    [center_x, center_y],
                    [center_x, 0],
                    [border_x, 0],
                    [border_x, center_y],
                    point
            ];
        }else if (cAngle < Math.PI )    {
            polygon = [
                    [center_x, center_y],
                    [center_x, 0],
                    [border_x, 0],
                    [border_x, border_y],
                    point
            ];
        } else if (cAngle < Math.PI*1.25)    {
            polygon = [
                    [center_x, center_y],
                    [center_x, 0],
                    [border_x, 0],
                    [border_x, border_y],
                    [center_x, border_y],
                    point
            ];
        }else if (cAngle < Math.PI*1.5)    {
            polygon = [
                    [center_x, center_y],
                    [center_x, 0],
                    [border_x, 0],
                    [border_x, border_y],
                    [0, border_y],
                    point
            ];
        }else if (cAngle < Math.PI*1.75)    {
            polygon = [
                    [center_x, center_y],
                    [center_x, 0],
                    [border_x, 0],
                    [border_x, border_y],
                    [0, border_y],
                    [0, center_y],
                    point
            ];
        }else {
            polygon = [
                    [center_x, center_y],
                    [center_x, 0],
                    [border_x, 0],
                    [border_x, border_y],
                    [0, border_y],
                    [0, 0],
                    point
            ];
        }
        return polygon;
    }

    //! Called when this View is removed from the screen. Save the
    //! state of this View here. This includes freeing resources from
    //! memory.
    function onHide() {
        Sys.println("view : onHide");
    }

    //! The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
        Sys.println("view : onExitSleep");
    }

    //! Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
        Sys.println("view : onEnterSleep");
    }

    function onPosition(info) {
        var heading = info.heading;
        headingStr = headingToStr(heading);
        var headingDeg = ((180 * heading ) /  Math.PI);
        if (headingDeg < 0) {
            headingDeg += 360;
        }
        headingOnlyStr = headingDeg.format("%d") + "°";
        headingStr += " - " + headingDeg.format("%d");
        accuracyStr = info.accuracy.format("%d");
        speedFloat = info.speed * 1.943844492;
        speedStr = (info.speed * 1.943844492).format("%0.1f");
        Sys.println("speed: " +speedStr+ " (" +info.speed+ ") heading: " +headingStr+ " (" +heading+ ")  accuracy: " +accuracyStr);
    }

    function headingToStr(heading){
        var sixteenthPI = Math.PI / 16.0;
        if (heading >= 0 and heading < sixteenthPI){
            return "N";
        }else if (heading > 0 and heading < (3 * sixteenthPI)){
           return "NNE";
        }else if (heading > 0 and heading < (5 * sixteenthPI)){
           return "NE";
        }else if (heading > 0 and heading < (7 * sixteenthPI)){
           return "ENE";
        }else if (heading > 0 and heading < (9 * sixteenthPI)){
           return "E";
        }else if (heading > 0 and heading < (11 * sixteenthPI)){
           return "ESE";
        }else if (heading > 0 and heading < (13 * sixteenthPI)){
           return "SE";
        }else if (heading > 0 and heading < (15 * sixteenthPI)){
           return "SSE";
        }else if (heading > 0){
           return "S";
        }else if (heading < 0 and heading < (-15 * sixteenthPI)){
           return "S";
        }else if (heading < 0 and heading < (-13 * sixteenthPI)){
           return "SSW";
        }else if (heading < 0 and heading < (-11 * sixteenthPI)){
           return "SW";
        }else if (heading < 0 and heading < (-9 * sixteenthPI)){
           return "WSW";
        }else if (heading < 0 and heading < (-7 * sixteenthPI)){
           return "W";
        }else if (heading < 0 and heading < (-5 * sixteenthPI)){
           return "WNW";
        }else if (heading < 0 and heading < (-3 * sixteenthPI)){
           return "NW";
        }else if (heading < 0 and heading < -sixteenthPI){
           return "NNW";
        }else {
            return "N";
        }
    }
}


    function secToStr(raceTime){
        var raceSec = (raceTime % 60).format("%02d");
        var raceMin = ((raceTime / 60) % 60).format("%02d");
        var raceHours = ((raceTime / 3600) % 60).format("%02d");

        return ""+raceHours+":"+raceMin+":"+raceSec;
    }
