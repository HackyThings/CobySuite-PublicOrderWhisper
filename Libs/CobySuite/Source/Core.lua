-- CobySuite: Shared library for all CobySuite addons
-- All shared utilities, UI factories, and infrastructure live here.
-- Individual addons (CobySniper, CobysLinkepedia, etc.) depend on this.

CobySuite_PublicOrderWhisper = CobySuite_PublicOrderWhisper or {}

-- Sub-namespace declarations (populated by individual modules)
CobySuite_PublicOrderWhisper.Utilities = CobySuite_PublicOrderWhisper.Utilities or {}
CobySuite_PublicOrderWhisper.UI        = CobySuite_PublicOrderWhisper.UI or {}
CobySuite_PublicOrderWhisper.Debug     = CobySuite_PublicOrderWhisper.Debug or {}
CobySuite_PublicOrderWhisper.Config    = CobySuite_PublicOrderWhisper.Config or {}
CobySuite_PublicOrderWhisper.EventBus  = CobySuite_PublicOrderWhisper.EventBus or {}
CobySuite_PublicOrderWhisper.Chat      = CobySuite_PublicOrderWhisper.Chat or {}
CobySuite_PublicOrderWhisper.Slash     = CobySuite_PublicOrderWhisper.Slash or {}
CobySuite_PublicOrderWhisper.Tests     = CobySuite_PublicOrderWhisper.Tests or {}

CobySuite_PublicOrderWhisper.SortDir = { ASC = "asc", DESC = "desc" }

-- Where this copy of the library comes from. The monorepo's CobySuite addon
-- leaves it as is; a standalone build embeds the library under its own name
-- and replaces it from its Build.lua with { embedded = true, host = "<addon>",
-- commit = "<short sha>", dirty = <bool> }.
CobySuite_PublicOrderWhisper.BuildInfo = CobySuite_PublicOrderWhisper.BuildInfo or { embedded = false }

-- The library version for reports: "embedded in <host> at <commit>" in a
-- standalone build, else the CobySuite addon's TOC version. The addon name
-- below is the only string literal in shipped shared code that is exactly
-- the library's name (the standalone build checks this; Source/Tests/ is
-- stripped).
function CobySuite_PublicOrderWhisper.LibraryVersionText()
  local info = CobySuite_PublicOrderWhisper.BuildInfo
  if info and info.embedded then
    return ("embedded in %s at %s"):format(tostring(info.host or "?"), tostring(info.commit or "?"))
  end
  return C_AddOns.GetAddOnMetadata("CobySuite", "Version") or "?"
end
