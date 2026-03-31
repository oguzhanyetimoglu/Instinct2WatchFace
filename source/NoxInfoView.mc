import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.SensorHistory;
import Toybox.Weather;
import Toybox.Position;

class NoxInfoView extends WatchUi.WatchFace {

    var _secX as Number = 0; // seconds x position, set in onUpdate for use in onPartialUpdate
    var _fgColor as Number = Graphics.COLOR_WHITE;
    var _bgColor as Number = Graphics.COLOR_BLACK;

    var _bmpFootprints as WatchUi.BitmapResource?;
    var _bmpBluetooth  as WatchUi.BitmapResource?;
    var _bmpMessage    as WatchUi.BitmapResource?;
    var _bmpHeartRate  as WatchUi.BitmapResource?;
    var _bmpHumidity   as WatchUi.BitmapResource?;
    var _bmpSunrise    as WatchUi.BitmapResource?;

    function initialize() {
        WatchFace.initialize();
        _bmpFootprints = WatchUi.loadResource(Rez.Drawables.icon_footprints)     as WatchUi.BitmapResource;
        _bmpBluetooth  = WatchUi.loadResource(Rez.Drawables.icon_bluetooth)      as WatchUi.BitmapResource;
        _bmpMessage    = WatchUi.loadResource(Rez.Drawables.icon_message)         as WatchUi.BitmapResource;
        _bmpHeartRate  = WatchUi.loadResource(Rez.Drawables.icon_heart_rate)     as WatchUi.BitmapResource;
        _bmpHumidity   = WatchUi.loadResource(Rez.Drawables.icon_humidity)       as WatchUi.BitmapResource;
        _bmpSunrise    = WatchUi.loadResource(Rez.Drawables.icon_sunrise_sunset) as WatchUi.BitmapResource;
    }

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    function onShow() as Void {}

    function conditionLabel(cond as Number) as String {
        if      (cond == 0)  { return "Clear";                  }
        else if (cond == 1)  { return "Partly Cloudy";          }
        else if (cond == 2)  { return "Mostly Cloudy";          }
        else if (cond == 3)  { return "Rain";                   }
        else if (cond == 4)  { return "Snow";                   }
        else if (cond == 5)  { return "Windy";                  }
        else if (cond == 6)  { return "Thunderstorms";          }
        else if (cond == 7)  { return "Wintry Mix";             }
        else if (cond == 8)  { return "Fog";                    }
        else if (cond == 9)  { return "Hazy";                   }
        else if (cond == 10) { return "Hail";                   }
        else if (cond == 11) { return "Scattered Showers";      }
        else if (cond == 12) { return "Scattered T-Storms";     }
        else if (cond == 13) { return "Unknown Precipitation";  }
        else if (cond == 14) { return "Light Rain";             }
        else if (cond == 15) { return "Heavy Rain";             }
        else if (cond == 16) { return "Light Snow";             }
        else if (cond == 17) { return "Heavy Snow";             }
        else if (cond == 18) { return "Light Rain/Snow";        }
        else if (cond == 19) { return "Heavy Rain/Snow";        }
        else if (cond == 20) { return "Cloudy";                 }
        else if (cond == 21) { return "Rain/Snow";              }
        else if (cond == 22) { return "Partly Clear";           }
        else if (cond == 23) { return "Mostly Clear";           }
        else if (cond == 24) { return "Light Showers";          }
        else if (cond == 25) { return "Showers";                }
        else if (cond == 26) { return "Heavy Showers";          }
        else if (cond == 27) { return "Chance of Showers";      }
        else if (cond == 28) { return "Thunderstorm Chance";    }
        else if (cond == 29) { return "Mist";                   }
        else if (cond == 30) { return "Dust";                   }
        else if (cond == 31) { return "Drizzle";                }
        else if (cond == 32) { return "Tornado";                }
        else if (cond == 33) { return "Smoke";                  }
        else if (cond == 34) { return "Ice";                    }
        else if (cond == 35) { return "Sand";                   }
        else if (cond == 36) { return "Squall";                 }
        else if (cond == 37) { return "Sandstorm";              }
        else if (cond == 38) { return "Volcanic Ash";           }
        else if (cond == 39) { return "Haze";                   }
        else if (cond == 40) { return "Fair";                   }
        else if (cond == 41) { return "Hurricane";              }
        else if (cond == 42) { return "Tropical Storm";         }
        else if (cond == 43) { return "Chance of Snow";         }
        else if (cond == 44) { return "Chance of Rain/Snow";    }
        else if (cond == 45) { return "Cloudy, Rain Chance";    }
        else if (cond == 46) { return "Cloudy, Snow Chance";    }
        else if (cond == 47) { return "Cloudy, Chance R/S";     }
        else if (cond == 48) { return "Flurries";               }
        else if (cond == 49) { return "Freezing Rain";          }
        else if (cond == 50) { return "Sleet";                  }
        else if (cond == 51) { return "Ice/Snow";               }
        else if (cond == 52) { return "Thin Clouds";            }
        else if (cond == 53) { return "Unknown Precip.";        }
        return "";
    }

    function onUpdate(dc as Dc) as Void {
        View.onUpdate(dc);

        var clockTime = System.getClockTime();

        // --- Heart rate ---
        var hr = "--";
        var actInfo = Activity.getActivityInfo();
        if (actInfo != null && actInfo.currentHeartRate != null) {
            hr = actInfo.currentHeartRate.format("%d");
        }

        // --- Stress ---
        var stress = 0;
        if (SensorHistory has :getStressHistory) {
            var iter = SensorHistory.getStressHistory({:period => 1, :order => SensorHistory.ORDER_NEWEST_FIRST});
            if (iter != null) {
                var sample = iter.next();
                if (sample != null && sample.data != null) {
                    stress = sample.data;
                }
            }
        }

        // --- Steps ---
        var steps = "--";
        var actMonInfo = ActivityMonitor.getInfo();
        if (actMonInfo != null && actMonInfo.steps != null) {
            steps = actMonInfo.steps.format("%d");
        }

        // --- Weather ---
        var temp        = "--\u00b0";
        var humidity    = "--%";
        var highTemp    = "--\u00b0";
        var lowTemp     = "--\u00b0";
        var weatherCond = -1;
        if (Weather has :getCurrentConditions) {
            var cond = Weather.getCurrentConditions();
            if (cond != null) {
                if (cond.temperature      != null) { temp        = cond.temperature.format("%d")      + "\u00b0"; }
                if (cond.relativeHumidity != null) { humidity    = cond.relativeHumidity.format("%d") + "%";      }
                if (cond.highTemperature  != null) { highTemp    = cond.highTemperature.format("%d")  + "\u00b0"; }
                if (cond.lowTemperature   != null) { lowTemp     = cond.lowTemperature.format("%d")   + "\u00b0"; }
                if (cond.condition        != null) { weatherCond = cond.condition;                                }
            }
        }

        // --- Sunrise / Sunset ---
        var sunriseStr = "--:--";
        var sunsetStr  = "--:--";
        var sunriseMin = 6 * 60 + 30;
        var sunsetMin  = 19 * 60 + 45;
        if (Weather has :getSunrise) {
            var posInfo = Position.getInfo();
            if (posInfo != null && posInfo.position != null) {
                var now = Time.now();
                var srM = Weather.getSunrise(posInfo.position, now);
                if (srM != null) {
                    var sr = Gregorian.info(srM, Time.FORMAT_SHORT);
                    sunriseMin = sr.hour * 60 + sr.min;
                    sunriseStr = Lang.format("$1$:$2$", [sr.hour.format("%02d"), sr.min.format("%02d")]);
                }
                var ssM = Weather.getSunset(posInfo.position, now);
                if (ssM != null) {
                    var ss = Gregorian.info(ssM, Time.FORMAT_SHORT);
                    sunsetMin = ss.hour * 60 + ss.min;
                    sunsetStr = Lang.format("$1$:$2$", [ss.hour.format("%02d"), ss.min.format("%02d")]);
                }
            }
        }

        // --- Date ---
        var days  = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"];
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var dayDateStr = Lang.format("$1$, $2$.$3$", [
            days[today.day_of_week - 1],
            today.day.format("%02d"),
            today.month.format("%02d")
        ]);

        // --- Bluetooth / Notifications ---
        var devSettings   = System.getDeviceSettings();
        var isBtConnected = devSettings.phoneConnected;
        var notifCount    = devSettings.notificationCount;

        // --- Reverse Colors ---
        var reverseColors = Application.Properties.getValue("ReverseColors") as Boolean;
        var fgColor = (reverseColors == true) ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
        var bgColor = (reverseColors == true) ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
        _bgColor = bgColor;
        _fgColor = fgColor;
        dc.setColor(Graphics.COLOR_TRANSPARENT, bgColor);
        dc.clear();
        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);

        // Row 1: Steps
        if (_bmpFootprints != null) { dc.drawBitmap(40, 6, _bmpFootprints); }
        dc.drawText(57, 13, Graphics.FONT_XTINY, steps,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // Row 2: Bluetooth + Notifications
        var iconY = 25;
        var iconX = 40;
        if (isBtConnected && _bmpBluetooth != null) {
            dc.drawBitmap(iconX, iconY, _bmpBluetooth);
            iconX += 20;
        }
        if (notifCount > 0 && _bmpMessage != null) {
            dc.drawBitmap(iconX, iconY, _bmpMessage);
            dc.drawText(iconX + 18, iconY + 8, Graphics.FONT_XTINY, notifCount.format("%d"),
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // Stress ring (r=27, penWidth=4 → outer edge stays at ~29, grows inward)
        var sweep = (stress * 360.0 / 100.0).toNumber();
        dc.setPenWidth(3);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(144, 31, 27, Graphics.ARC_CLOCKWISE, 90, 90 - 360);
        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        if (sweep > 0) {
            dc.drawArc(144, 31, 27, Graphics.ARC_CLOCKWISE, 90, 90 - sweep);
        }
        dc.setPenWidth(1);
        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);

        // Heart rate (inside bezel circle)
        if (_bmpHeartRate != null) { dc.drawBitmap(136, 7, _bmpHeartRate); }
        dc.drawText(144, 39, Graphics.FONT_LARGE, hr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Date — fixed position, centered
        dc.drawText(20, 52, Graphics.FONT_SMALL, dayDateStr,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // Time + seconds (horizontally centered as a group)
        var timeStr   = Lang.format("$1$:$2$", [clockTime.hour.format("%02d"), clockTime.min.format("%02d")]);
        var secStr    = clockTime.sec.format("%02d");
        var timeW     = dc.getTextDimensions(timeStr, Graphics.FONT_NUMBER_THAI_HOT)[0];
        var secW      = dc.getTextDimensions(secStr,  Graphics.FONT_LARGE)[0];
        var gap       = 6;
        var groupLeft = 88 - (timeW + gap + secW) / 2;
        _secX = groupLeft + timeW + gap;

        dc.drawText(groupLeft + timeW / 2, 82, Graphics.FONT_NUMBER_THAI_HOT, timeStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(groupLeft + timeW + gap, 86, Graphics.FONT_LARGE, secStr,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // Weather condition label (below time)
        var condStr = conditionLabel(weatherCond);
        if (!condStr.equals("")) {
            dc.drawText(88, 112, Graphics.FONT_XTINY, condStr,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // Weather row: temp | low/high | humidity
        dc.drawText(20,  132, Graphics.FONT_XTINY, temp,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(88,  132, Graphics.FONT_XTINY, lowTemp + "/" + highTemp,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(156, 132, Graphics.FONT_XTINY, humidity,
            Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);

        // 24h timeline bar (x=20..156, y=146)
        // Night = checkerboard, day = solid, now = vertical marker
        var tlX1   = 20;
        var tlX2   = 156;
        var tlW    = tlX2 - tlX1;
        var tlY    = 146;
        var nowMin = clockTime.hour * 60 + clockTime.min;
        var srX    = tlX1 + (sunriseMin * tlW / (24 * 60));
        var ssX    = tlX1 + (sunsetMin  * tlW / (24 * 60));
        var nowX   = tlX1 + (nowMin     * tlW / (24 * 60));

        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        for (var xi = tlX1; xi <= srX - 2; xi++) {
            if ((xi - tlX1) % 2 == 0) {
                dc.fillRectangle(xi, tlY, 1, 1);
            } else {
                dc.fillRectangle(xi, tlY - 1, 1, 1);
                dc.fillRectangle(xi, tlY + 1, 1, 1);
            }
        }
        dc.fillRectangle(srX, tlY - 1, ssX - srX, 3);
        for (var xi2 = ssX + 1; xi2 <= tlX2; xi2++) {
            if ((xi2 - ssX - 1) % 2 == 0) {
                dc.fillRectangle(xi2, tlY, 1, 1);
            } else {
                dc.fillRectangle(xi2, tlY - 1, 1, 1);
                dc.fillRectangle(xi2, tlY + 1, 1, 1);
            }
        }
        dc.fillRectangle(nowX - 1, tlY - 6, 2, 13);

        // Sunrise / Sunset
        dc.drawText(32,  160, Graphics.FONT_XTINY, sunriseStr,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        if (_bmpSunrise != null) { dc.drawBitmap(80, 153, _bmpSunrise); }
        dc.drawText(100, 160, Graphics.FONT_XTINY, sunsetStr,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function onPartialUpdate(dc as Dc) as Void {
        var secStr = System.getClockTime().sec.format("%02d");
        var secW   = dc.getTextDimensions(secStr, Graphics.FONT_LARGE)[0];
        var secH   = dc.getTextDimensions(secStr, Graphics.FONT_LARGE)[1];
        dc.setClip(_secX - 1, 86 - secH / 2 - 1, secW + 4, secH + 2);
        dc.setColor(_bgColor, _bgColor);
        dc.fillRectangle(_secX - 1, 86 - secH / 2 - 1, secW + 4, secH + 2);
        dc.setColor(_fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_secX, 86, Graphics.FONT_LARGE, secStr,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.clearClip();
    }

    function onHide() as Void {}
    function onExitSleep() as Void {}
    function onEnterSleep() as Void {}

}
