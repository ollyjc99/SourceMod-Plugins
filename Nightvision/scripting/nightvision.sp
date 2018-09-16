#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "Night Vision",
	author = "FaZe IlLuMiNaTi",
	description = "Give players Night Vision goggles",
	version = "1",
	url = "steamcommunity.com/id/FaZe_IlLuMiNaTi"
}

public OnPluginStart()
{
	HookEvent("player_spawn", SpawnEvent);
	AddCommandListener(NightVision, "rebuy"); //Listen for the "rebuy" command (bound to F4 by default)
}

public SpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId( GetEventInt( event, "userid" ));
	if ( IsValidClient( client ))
	{
		GivePlayerItem(client, "item_nvgs"); //When the player spawns, give them Night Vision goggles
	}
}

public Action:NightVision(client, const String:command[], args)
{
	ClientCommand(client, "nightvision"); //When the client sends the "rebuy" command, make them execute "nightvision" instead
	return Plugin_Handled;
}

stock bool IsValidClient(int client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}