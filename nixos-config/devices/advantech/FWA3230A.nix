{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.snabb.devices.advantech;
in
{
  config = mkIf cfg.FWA3230A.enable {
    services.lcd4linux = let
      display = "CW12832";
    in {
      enable = true;
      display = {
        name = "${display}";
        driver = "Cwlinux";
        model = "CW12232";
        port = "/dev/ttyS1";
        speed = 19200;
        size = "21x4";
        brightness = 1;
        icons = 1;
      };
      literalConfig = ''
        Widget OS {
          class 'Text'
          expression uname('nodename')
          width 20
          align 'L'
          speed 100
          update tick
        }
        Widget Time {
          class 'Text'
          expression strftime('%a %d/%m/%y %H:%M:%S',time())
          width 21
          align 'L'
          update 1000
        }
        Widget RAM {
          class  'Text'
          expression meminfo('MemFree')/1024
          prefix 'Free RAM: '
          postfix ' MB'
          width  21
          precision 0
          align  'R'
          update tick
        }
        Widget Busy {
          class 'Text'
          expression proc_stat::cpu('busy', 500)
          prefix 'Busy'
          postfix '%'
          width 10
          precision 1
          align 'R'
          update tick
        }
        Widget BusyBar {
          class 'Bar'
          expression  proc_stat::cpu('busy',   500)
          expression2 proc_stat::cpu('system', 500)
          length 10
          direction 'E'
          update tack
        }

        Widget CPU {
          class  'Text'
          expression  uname('machine')
          prefix 'CPU '
          width  9
          align  'L'
          update tick
        }
        
        Widget Load {
          class 'Text'
          expression loadavg(1)
          prefix 'Load'
          postfix loadavg(1)>1.0?'!':' '
          width 10
          precision 1
          align 'R'
          update tick
        }

        Widget keyup {
          class 'Keypad'
          position 'up'
          state 'pressed'
          expression brightness = brightness + 1; LCD::brightness(brightness)
        }

        Widget keydown {
          class 'Keypad'
          position 'down'
          state 'pressed'
          expression brightness = brightness - 1;  LCD::brightness(brightness)
        }

        Variables {
          tick 500
          tack 100
          minute 60000
        }

        Variable {
          brightness 1
        }

        Layout Default {
          Row1 {
            Col1  'OS'
          }
          Row2 {
            Col1  'Load'
          }
          Row3 {
            Col1  'RAM'
          }
          Row4 {
            Col1  'Busy'
            Col11 'BusyBar'
          }
          Keypad1 'keyup'
          Keypad2 'keydown'
        }

        Display '${display}'
        Layout  'Default'
      '';
    };

  };
}

