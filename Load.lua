return function(a,b)do a=a or"Module"assert(a=="NPC"or a=="Module","invalid type for module (NPC or Module)")b=b or tostring(game.PlaceId)local c=typeof(b)local d="invalid type for %s (expected %s, got %s)"assert(c=="string",d:format("PatchName","string",c))end local c="https://raw.githubusercontent.com/worstify/Aiming/main/GamePatches/%s/%s.lua"local d,e=pcall(function()local d=c:format(a,b);(loadstring(game:HttpGet(d)))()end)if not d then local b="https://raw.githubusercontent.com/worstify/Aiming/main/%s.lua";(loadstring(game:HttpGet(b:format(a))))()end return a=="Module"and Aiming or AimingNPC end