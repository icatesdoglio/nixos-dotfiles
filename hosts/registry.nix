# Central host registry.
# Add an entry here whenever a new machine joins the WireGuard network.
# Both Pi-hole DNS reservations and the ServeMato WireGuard peer list are
# generated from this file automatically — no other files need editing.
#
# Fields:
#   wgIP        — WireGuard tunnel IP (required for all peers)
#   wgPublicKey — WireGuard public key (required for all peers)
#   lanIP       — LAN IP, if the host has a static LAN address (optional)
{
  servemato = {
    wgIP = "10.100.0.1";
    lanIP = "192.168.0.30";
    wgPublicKey = "Cc+IKGfzGNfcS4/InZY89EBtPvXydjs4Ae5/AgBmq0Y=";
  };
  gp-linux = {
    wgIP = "10.100.0.2";
    lanIP = "192.168.0.20";
    wgPublicKey = "E3J+BJ2f+6VyLY8JB7ypzSOXdQsB66T/nr7mdcP4yxc=";
  };
  mini-mine = {
    wgIP = "10.100.0.3";
    lanIP = "192.168.0.40";
    wgPublicKey = "GXxa4bsYmIeLdvnznaNiX8kzOwfjoRCJTMG3uUrFCXk=";
  };
  iphone = {
    wgIP = "10.100.0.4";
    wgPublicKey = "hlZRXkdEdoHLpigkr3cP23X2qu89tf1Lj3hUbeMtGAw=";
  };
  archlaptop = {
    wgIP = "10.100.0.5";
    wgPublicKey = "mx/c3oFZwTQ824bA4kXPyr+CU0qVLO28imgENyEZgUU=";
  };
  framework = {
    wgIP = "10.100.0.6";
    lanIP = "192.168.0.42";
    wgPublicKey = "8A7L4okGuJSPtHIHxVNcTT18iGKr50Ipz18G9LAQKgE=";
  };
  pepper = {
    wgIP = "10.100.0.7";
    wgPublicKey = "MH26xzZZKjtGK5gCJcfgh1T1RQ0rLqH3JThwOFi07Rs=";
  };
}
# vim: ts=2 sts=2 sw=2 et
