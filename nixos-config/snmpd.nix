{ config, pkgs, lib, ... }:

with lib;

{
  services.snmpd = let
    listenOn = {
      ipv4 = [ "127.0.0.1" ];
      ipv6 = [ "::1" ];
    };
    roCommunities = {
      public = {
        sources4 = [ "127.0.0.1" ];
        sources6 = [ "::1" ];
      };
    };

    mkAgentAddress = address: proto:
      { inherit proto address; port = 161; };
    mkAgentAddresses = addresses: proto:
      map (address: mkAgentAddress address proto) addresses;
    mkCommunity = attr: community: set:
      let
        sources = attrByPath [ attr ] null set;
        view = attrByPath [ "view" ] null set;
      in
        if (sources != null) then
          concatMap (source: singleton { inherit community source view; }) sources
        else
          null;
    mkCommunities = attr: set:
      remove null (flatten (mapAttrsToList (n: v: mkCommunity attr n v) set));
  in {
    enable = true;
    agentAddresses = mkAgentAddresses listenOn.ipv4 "udp" ++
                     mkAgentAddresses listenOn.ipv6 "udp6";
    communities = {
      ro = mkCommunities "sources4" roCommunities;
      ro6 = mkCommunities "sources6" roCommunities;
    };
  };
}
