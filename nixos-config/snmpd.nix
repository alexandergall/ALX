{ config, pkgs, lib, ... }:

with lib;

{
  services.snmpd = let
    community  = "public";
    sysUpTime = "sysUpTime";
  in {
    enable = true;
    agentAddresses = [
      { proto = "udp"; address = "127.0.0.1"; port = 161; }
      { proto = "udp6"; address = "::1"; port = 161; }
    ];
    communities = {
      ro = [
        { inherit community; source = "127.0.0.1"; }
        { community = "snabb"; source = "127.0.0.1"; view = sysUpTime; }
      ];
      ro6 = [
        { inherit community; source = "::1"; }
        { community = "snabb"; source = "::1"; view = sysUpTime; }
      ];
    };

    ## The Snabb SNMP sub-agent uses community "snabb" to read
    ## sysUpTime in order to be independent of the "public" community.
    views.${sysUpTime} = {
      type = "included";
      oid = ".1.3.6.1.2.1.1.3";
    };
  };
}
