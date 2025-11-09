-- Test script to check what functions Solara supports
-- Run this in Solara to see what's available

print("=== Executor Function Test ===")
print("")

local functions = {
    "readfile",
    "writefile",
    "loadstring",
    "queue_on_teleport",
    "hookmetamethod",
    "hookfunction",
    "getnamecallmethod",
    "checkcaller",
    "setthreadidentity",
    "getrenv",
    "getupvalue",
    "setupvalue",
    "gethiddenproperty",
    "sethiddenproperty",
    "mousemoverel",
    "mouse1press",
    "mouse1release",
    "isrbxactive",
    "setclipboard",
    "getconnections"
}

local available = {}
local missing = {}

for _, funcName in ipairs(functions) do
    if _G[funcName] then
        table.insert(available, funcName)
        print("✓ " .. funcName .. " - AVAILABLE")
    else
        table.insert(missing, funcName)
        print("✗ " .. funcName .. " - MISSING")
    end
end

print("")
print("=== Summary ===")
print("Available: " .. #available .. "/" .. #functions)
print("Missing: " .. #missing .. "/" .. #functions)

if _G.readfile then
    print("")
    print("=== Testing readfile ===")
    local success, result = pcall(function()
        return readfile("test.txt")
    end)

    if success then
        print("✓ readfile works!")
        print("Content: " .. tostring(result))
    else
        print("✗ readfile error: " .. tostring(result))
        print("  (This is normal if test.txt doesn't exist)")
    end
end

print("")
print("=== Executor Info ===")
if identifyexecutor then
    print("Executor: " .. identifyexecutor())
else
    print("Executor: Unknown (identifyexecutor not available)")
end
