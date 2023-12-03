{ depot, ... }:

{
  dns.records = let
    cdnShieldAddr = [ depot.hours.VEGAS.interfaces.primary.addrPublic ];
  in {
    "fonts-googleapis-com.cdn-shield".target = cdnShieldAddr;
    "fonts-gstatic-com.cdn-shield".target = cdnShieldAddr;
    "cdnjs-cloudflare-com.cdn-shield".target = cdnShieldAddr;
    "wttr-in.cdn-shield".target = cdnShieldAddr;
  };
}
