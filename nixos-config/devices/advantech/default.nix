{ config, ... }:

{ 
  imports = [ ./FWA3230A.nix ];

  config.services.snabb.devices =
      let
        driver10g = {
          path = "apps.intel.intel_app";
          name = "Intel82599";
        };
        driver1g = {
          path = "apps.intel.intel1g";
          name = "Intel1g";
        };
      in
      {
        advantech = {
          FWA3230A = {
            interfaces = [
              ## GigE interfaces in top row labelled MGMT0, MGMT1
              {
                name = "GigE1/0";
                nicConfig = {
                  pciAddress = "0000:0c:00.0";
                  driver = driver1g;
                };
              }
              {
                name = "GigE1/1";
                nicConfig = {
                  pciAddress = "0000:0d:00.0";
                  driver = driver1g;
                };
              }
              ## GigE interfaces in bottom row, labelled 1 through 6
              {
                name = "GigE2/1";
                nicConfig = {
                  pciAddress = "0000:06:00.0";
                  driver = driver1g;
                };
              }
              {
                name = "GigE2/2";
                nicConfig = {
                  pciAddress = "0000:07:00.0";
                  driver = driver1g;
                };
              }
              {
                name = "GigE2/3";
                nicConfig = {
                  pciAddress = "0000:08:00.0";
                  driver = driver1g;
                };
              }
              {
                name = "GigE2/4";
                nicConfig = {
                  pciAddress = "0000:09:00.0";
                  driver = driver1g;
                };
              }
              {
                name = "GigE2/5";
                nicConfig = {
                  pciAddress = "0000:0a:00.0";
                  driver = driver1g;
                };
              }
              {
                name = "GigE2/6";
                nicConfig = {
                  pciAddress = "0000:0b:00.0";
                  driver = driver1g;
                };
              }

              ## TenGigE in left mezzanine slot labelled 1 and 2
              {
                name = "TenGigE1/1";
                nicConfig = {
                  pciAddress = "0000:03:00.0";
                  driver = driver10g;
                };
              }
              {
                name = "TenGigE1/2";
                nicConfig = {
                  pciAddress = "0000:03:00.1";
                 driver= driver10g;
                };
              }

              ## TenGigE in right mezzanine slot labelled 1 and 2
              {
                name = "TenGigE2/1";
                nicConfig = {
                  pciAddress = "0000:04:00.0";
                 driver= driver10g;
                };
              }
              {
                name = "TenGigE2/2";
                nicConfig = {
                  pciAddress = "0000:04:00.1";
                 driver= driver10g;
                };
              }
            ];
          }; ## FWA3230A
        };
      };
}
