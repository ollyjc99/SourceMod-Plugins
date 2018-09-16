//Imports
#include <sourcemod>
#include <colors>
#include <sdktools>
#include <sdkhooks>






//Plugin information
public Plugin:myinfo = 
{
	name = "ecksdee",
	author = "FaZe IlLuMiNaTi",
	description = "lol kappa",
	version = "1",
	url = "http://glorified.eu"
}


/*

Colors in Colors.inc

Default - Works
Darkred - Works
Green - Works (comes out as light green)
Lightgreen - Works
Red - Dosen't work
Blue - Only works on CT
Olive - Works
Lime - Works
Lightred - Works
Purple - Works (hard to read)
Grey - Works
Orange - Works

*/




//Setting up variables
new Handle:g_hLocked = INVALID_HANDLE;
new Handle:g_noclip = INVALID_HANDLE;
new Handle:g_kill = INVALID_HANDLE;
new Handle:g_god = INVALID_HANDLE;
new Handle:g_bhop = INVALID_HANDLE;
new bool:g_godenabled[MAXPLAYERS + 1];
new bool:g_ncenabled[MAXPLAYERS + 1];
new bool:g_autohopenabled[MAXPLAYERS + 1];

Handle hBhop;
bool CSGO;
int WATER_LIMIT;


/*Everything in the following section is executed upon startup
Commands, CVARs and Hooks are defined here*/
public OnPluginStart()
{
	//Admin Commands - Only admins can run these commands
	RegAdminCmd("sm_warmup", StartWarmup, ADMFLAG_SLAY, "Starting Warmup"); //!warmup
	RegAdminCmd("sm_knife", StartKnife, ADMFLAG_SLAY, "Starting Knife Round"); //!knife
	RegAdminCmd("sm_start", StartGame, ADMFLAG_SLAY, "Starting Game"); //!start
	RegAdminCmd("sm_play", StartGame, ADMFLAG_SLAY, "Starting Game"); //!play
	RegAdminCmd("sm_scramble", Scramble, ADMFLAG_SLAY, "Scrambling Teams"); //!scramble
	RegAdminCmd("sm_swap", Swap, ADMFLAG_SLAY, "Swapping Teams"); //!swap
	RegAdminCmd("sm_switch", Swap, ADMFLAG_SLAY, "Swapping Teams"); //!switch
	RegAdminCmd("sm_pause", PauseGame, ADMFLAG_SLAY, "Pausing Game"); //!pause
	RegAdminCmd("sm_unpause", UnPauseGame, ADMFLAG_SLAY, "Unpausing Game"); //!unpause
	RegAdminCmd("sm_reload", Reload, ADMFLAG_SLAY, "Reloading Plugin"); //!reload
	RegAdminCmd("sm_clearchat", ClearChat, ADMFLAG_SLAY, "Clearing Chat"); //!clearchat
	RegAdminCmd("sm_ccg", ClearChat, ADMFLAG_SLAY, "Clear Global Chat"); //!ccg
	RegAdminCmd("sm_cc", ClearChat, ADMFLAG_SLAY, "Clear Global Chat"); //!cc
	RegAdminCmd("sm_enablenoclip", ToggleNoClipOn, ADMFLAG_SLAY, "NoClip Enable"); //!enablenoclip
	RegAdminCmd("sm_disablenoclip", ToggleNoClipOff, ADMFLAG_SLAY, "NoClip Disable"); //!disablenoclip
	RegAdminCmd("sm_bhop", Bhop, ADMFLAG_SLAY, "Enable Bhopping") //!bhop
	RegAdminCmd("sm_enablegod", ToggleGodModeOn, ADMFLAG_SLAY, "Enable God") //!bhop
	RegAdminCmd("sm_disablegod", ToggleGodModeOff, ADMFLAG_SLAY, "Disable God") //!bhop
	RegAdminCmd("sm_reset", ResetCFG, ADMFLAG_SLAY, "Reset") //!reset
	//RegAdminCmd("sm_hopping", AutoHopper, ADMFLAG_SLAY, "hop") //!reset

	//Player Commands - Everyone can run these commands
	RegConsoleCmd("sm_ws", EcksDee, "lol") //!ws
	RegConsoleCmd("sm_noclip", ToggleNoClip, "Noclip"); //!noclip
	RegConsoleCmd("sm_nc", ToggleNoClip, "Noclip"); //!nc
	RegConsoleCmd("sm_autohop", AutoHop, "AutoHop") //!autohop
	RegConsoleCmd("sm_autobhop", AutoHop, "AutoHop") //!autobhop
	RegConsoleCmd("sm_god", GodMode, "Enable God Mode"); //!god
	RegConsoleCmd("sm_help", PluginHelp, "Help") //!help
	RegConsoleCmd("sm_colours", PrintColors, "Colours") //!colours
	RegConsoleCmd("sm_colors", PrintColors, "Colors") //!colors
	RegConsoleCmd("sm_ccl", ClearLocalChat, "Clear Local Chat") //!ccl
	
	//Command Listeners and Hooks - Command listeners will handle pre-existing CS:GO console commands
	AddCommandListener(NoKill, "kill");
	AddCommandListener(Command_JoinTeam, "jointeam");
	HookEvent("server_cvar", Event_ServerCvar, EventHookMode_Pre);

	//Creating CVARs
	g_hLocked = CreateConVar("sm_lock_teams", "0", "Enable or disable locking teams during match", FCVAR_NOTIFY);
	g_noclip = CreateConVar("sm_noclipenable", "0", "Enable or disable noclip", FCVAR_NOTIFY);
	g_kill = CreateConVar("sm_disablekill", "0", "Enable or disable kill command", FCVAR_NOTIFY);
	g_god = CreateConVar("sm_godmodeenable", "0", "Enable or disable god command", FCVAR_NOTIFY);
	g_bhop = CreateConVar("sm_bhopenable", "0", "Enable or disable bhop", FCVAR_NOTIFY);


	AutoExecConfig(true, "abnerbhop");
	hBhop = CreateConVar("sm_autohopenable", "0", "Enable/disable Plugin", FCVAR_NOTIFY|FCVAR_REPLICATED);
 
	char theFolder[40];
	GetGameFolderName(theFolder, sizeof(theFolder));
	CSGO = StrEqual(theFolder, "csgo");
	(CSGO) ? (WATER_LIMIT = 2) : (WATER_LIMIT = 1);
}

public OnClientPostAdminCheck(client)
{
	g_godenabled[client] = false;
	g_autohopenabled[client] = false;
	g_ncenabled[client] = false;
}


public OnClientDisconnect(client)
{
	g_godenabled[client] = false;
	g_autohopenabled[client] = false;
	g_ncenabled[client] = false;
}


//Help section
public Action:PluginHelp(client, args)
{
	CPrintToChat(client, ">> {green}Help");
	CPrintToChat(client, ">> {orange}!noclip or !nc {default}- {purple}Noclip");
	CPrintToChat(client, ">> {orange}!god {default}- {purple}God Mode");
	CPrintToChat(client, ">> {orange}!ws {default}- {purple}Choose a weapon skin");
	CPrintToChat(client, ">> {orange}!autobhop or !autohop {default}- {purple}AutoBhop");
	CPrintToChat(client, ">> {orange}!colors or !colours {default}- {purple}Prints all the colours to chat");
	CPrintToChat(client, ">> {orange}!ccl {default}- {purple}Clear Local Chat");
	return Plugin_Handled;
}

//Colors
public Action:PrintColors(client, args)
{
	CPrintToChat(client, ">> {default}Default - Works");
	CPrintToChat(client, ">> {darkred}Darkred - Works");
	CPrintToChat(client, ">> {green}Green - Works (comes out as light green)");
	CPrintToChat(client, ">> {lightgreen}Lightgreen - Works");
	CPrintToChat(client, ">> {red}Red - Dosen't work");
	CPrintToChat(client, ">> {blue}Blue - Only works on CT");
	CPrintToChat(client, ">> {olive}Olive - Works");
	CPrintToChat(client, ">> {lime}Lime - Works");
	CPrintToChat(client, ">> {lightred}Lightred - Works")
	CPrintToChat(client, ">> {purple}Purple - Works (hard to read)");
	CPrintToChat(client, ">> {grey}Grey - Works");
	CPrintToChat(client, ">> {orange}Orange - Works");
	return Plugin_Handled;
}

//Fresh
public Action:ResetCFG(client, args)
{
	ServerCommand("exec gamemode_competitive")
	CPrintToChatAll(">> {green}All settings reset to default")
	ServerCommand("mp_restartgame 1")
}

//Warmup
public Action:StartWarmup(client, args)
{
	ServerCommand("exec warmup");
	ClearChat(client, args);
	CPrintToChatAll(">> {grey}Warmup");
	CPrintToChatAll(">> {grey}Warmup");
	CPrintToChatAll(">> {grey}Warmup");
	return Plugin_Handled;
}

//Knife Round
public Action:StartKnife(client, args)
{
	ServerCommand("exec knife");
	ClearChat(client, args);
	CPrintToChatAll(">> {lime}Knife");
	CPrintToChatAll(">> {lime}Knife");
	CPrintToChatAll(">> {lime}Knife");
	return Plugin_Handled;
}

//Start Game
public Action:StartGame(client, args)
{
	ServerCommand("exec play");
	ClearChat(client, args);
	CPrintToChatAll(">> {green}LIVE");
	CPrintToChatAll(">> {green}LIVE");
	CPrintToChatAll(">> {green}LIVE");
	return Plugin_Handled;
}

//Scramble Teams
public Action:Scramble(client, args)
{
	ServerCommand("mp_scrambleteams");
	CPrintToChatAll(">> {orange}Teams have been scrambled");
	CPrintToChatAll(">> {orange}Teams have been scrambled");
	CPrintToChatAll(">> {orange}Teams have been scrambled");
	return Plugin_Handled;
}

//Swap Teams
public Action:Swap(client, args)
{
	ServerCommand("mp_swapteams");
	CPrintToChatAll(">> {olive}Teams have been swapped");
	CPrintToChatAll(">> {olive}Teams have been swapped");
	CPrintToChatAll(">> {olive}Teams have been swapped");
	return Plugin_Handled;
}


//Pause Game
public Action:PauseGame(client, args)
{
	ServerCommand("mp_pause_match");
	CPrintToChatAll("");
	CPrintToChatAll(">> {darkred}Game Paused");
	return Plugin_Handled;
}


//Unpause Game
public Action:UnPauseGame(client, args)
{
	ServerCommand("mp_unpause_match");
	CPrintToChatAll(">> {green}Game Unpaused");
	CPrintToChatAll("");
	return Plugin_Handled;
}


//Reload Plugin
public Action:Reload(client, args)
{
	ServerCommand("sm plugins reload ecksdee.smx");
	CPrintToChat(client, ">> {lightred}ecksdee");
	return Plugin_Handled;
}


//Disable "kill" command
public Action:NoKill(int client, const char[] command, int argc)
{
	if (GetConVarBool(g_kill))
	{
		CPrintToChat(client, ">> {lightred}You cannot suicide during a match!")
		return Plugin_Handled;
	}
	if(g_godenabled[client])
	{
		CPrintToChat(client, ">> {lightred}You cannot suicide when in God Mode!")
		return Plugin_Handled;
	}
	return Plugin_Continue;
}  

//Suppress CVAR Changes
public Action Event_ServerCvar(Event event, const char[] name, bool dontBroadcast)
{
	
	event.BroadcastDisabled = true;
	return Plugin_Continue;
}

//Enable/Disable Team Joining
public Action:Command_JoinTeam(client, const String:command[], args)
{
	if (client != 0)
	{
		if(IsClientInGame(client) && !IsFakeClient(client))
		{
			if (GetClientTeam(client) > 1 && GetConVarBool(g_hLocked))
			{
				CPrintToChat(client, ">> {lightred}You cannot switch teams during a match!");
				return Plugin_Stop;
			}
		}
	}

	return Plugin_Continue;
}  

//Basic NoClip
public Action:ToggleNoClip(client, args)
{

	if(GetConVarBool(g_noclip))
	{
		new MoveType:movetype = GetEntityMoveType(client);

		if(!g_ncenabled[client] && movetype != MOVETYPE_NOCLIP)
		{
			SetEntityMoveType(client, MOVETYPE_NOCLIP);
			g_ncenabled[client] = true;
			CPrintToChat(client, ">> {green}Noclip On");
		}
		else
		{
			SetEntityMoveType(client, MOVETYPE_WALK);
			g_ncenabled[client] = false;
			CPrintToChat(client, ">> {darkred}Noclip Off");
		}
	}
	else
	{
		CPrintToChat(client, ">> {lightred}Noclip is disabled");
	}
	return Plugin_Handled;
}

//Enable NoClip CVAR
public Action:ToggleNoClipOn(client, args)
{
	ServerCommand("sm_noclipenable 1");
	CPrintToChatAll(">> {green}Noclip Enabled");
	return Plugin_Handled;
}

//Disable NoClip CVAR
public Action:ToggleNoClipOff(client, args)
{
	ServerCommand("sm_noclipenable 0");
	g_ncenabled[client] = false;
	CPrintToChatAll(">> {darkred}Noclip Disabled");
	return Plugin_Handled;
}

//Toggle Godmode
public Action:GodMode(client, args)
{
	if(GetConVarBool(g_god))
	{
		if(!g_godenabled[client]) //If the player does not have godmode, set godmode.
		{
			SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
			g_godenabled[client] = true;
			CPrintToChat(client, ">> {green}God Mode On");
			return Plugin_Handled;
		}
		else //If the player has godmode, remove it.
		{
			SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
			g_godenabled[client] = false;
			CPrintToChat(client, ">> {darkred}God Mode Off");
			return Plugin_Handled;
		}
	}
	else
	{
		CPrintToChat(client, ">> {lightred}God Mode is disabled");
	}
	return Plugin_Handled;
}

//Enable GodMode CVAR
public Action:ToggleGodModeOn(client, args)
{
	ServerCommand("sm_godmodeenable 1");
	CPrintToChatAll(">> {green}God Mode Enabled");
	return Plugin_Handled;
}

//Disable GodMode CVAR
public Action:ToggleGodModeOff(client, args)
{
	ServerCommand("sm_godmodeenable 0");
	g_godenabled[client] = false;
	CPrintToChatAll(">> {darkred}God Mode Disabled");
	return Plugin_Handled;
}

//Enable Bhop
public Action:Bhop(client, args)
{
	if(!GetConVarBool(g_bhop))
	{
		ServerCommand("sm_realbhop_enabled 1");
		ServerCommand("sm_cvar sv_enablebunnyhopping 1");
		ServerCommand("sv_staminajumpcost 0");
		ServerCommand("sv_staminalandcost 0");
		ServerCommand("sv_airaccelerate 12000");
		SetConVarBool(g_bhop, true);
		SetConVarBool(hBhop, true);
		CPrintToChatAll(">> {green}Bhop Enabled");
		return Plugin_Handled;
	}
	else 
	{
		ServerCommand("sm_realbhop_enabled 0");
		ServerCommand("sm_cvar sv_enablebunnyhopping 0");
		ServerCommand("sv_staminajumpcost .080");
		ServerCommand("sv_staminalandcost .050");
		ServerCommand("sv_airaccelerate 12");
		SetConVarBool(g_bhop, false);
		SetConVarBool(hBhop, false);
		CPrintToChat(client, ">> {darkred}Bhop Disabled");
		return Plugin_Handled;
	}
}

/*
public Action:AutoHop(client, args)
{
	CPrintToChat(client, ">> {lightred}AutoHop is for noobs");
	return Plugin_Handled;
}
*/

public Action:EcksDee(client, args)
{
	CPrintToChat(client, ">> {lightred}http://steamcommunity.com/market");
	return Plugin_Handled;
}

//AutoHop
public Action:AutoHop(client, args)
{
	if(GetConVarBool(g_bhop))
	{
		if(!g_autohopenabled[client]) //If the player does not have autohop, set autohop
		{
			g_autohopenabled[client] = true;
			CPrintToChat(client, ">> {lightred}AutoHop is for noobs");
			CPrintToChat(client, ">> {green}AutoHop On");
			return Plugin_Handled;
		}
		else //If the player has autohop, remove it.
		{
			g_autohopenabled[client] = false;
			CPrintToChat(client, ">> {darkred}AutoHop Off");
			return Plugin_Handled;
		}
	}
	else
	{
		CPrintToChat(client, ">> {lightred}Bhop is disabled");
	}
	return Plugin_Handled;
}

public void OnClientPutInServer(int client)
{
	if(!CSGO) // To boost in CSGO use together https://forums.alliedmods.net/showthread.php?t=244387
		SDKHook(client, SDKHook_PreThink, PreThink); //This make you fly in CSS;
}

public Action PreThink(int client)
{
	if(IsValidClient(client) && IsPlayerAlive(client) && g_autohopenabled[client])
	{
		SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0); 
	}
}

stock void SetCvar(char[] scvar, char[] svalue)
{
	Handle cvar = FindConVar(scvar);
	SetConVarString(cvar, svalue, true);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(GetConVarInt(hBhop) == 1 && g_autohopenabled[client]) //Check if plugin and autobhop is enabled
		if (IsPlayerAlive(client) && buttons & IN_JUMP) //Check if player is alive and is in pressing space
			if(!(GetEntityMoveType(client) & MOVETYPE_LADDER) && !(GetEntityFlags(client) & FL_ONGROUND)) //Check if is not in ladder and is in air
				if(waterCheck(client) < WATER_LIMIT)
					buttons &= ~IN_JUMP; 
	return Plugin_Continue;
}

int waterCheck(int client)
{
	return GetEntProp(client, Prop_Data, "m_nWaterLevel");
}

stock bool IsValidClient(int client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}























/*

Old, obsolete Bhop code

//Enable Bhop
public Action:Bhop(client, args)
{
	if(!g_bhopenabled[client])
	{
		ServerCommand("sm_realbhop_enabled 1");
		ServerCommand("sm_cvar sv_enablebunnyhopping 1");
		ServerCommand("sv_staminajumpcost 0");
		ServerCommand("sv_staminalandcost 0");
		ServerCommand("sv_airaccelerate 12000");
		g_bhopenabled[client] = true;
		CPrintToChatAll(">> {green}Bhop Enabled");
		return Plugin_Handled;
	}
	else 
	{
		ServerCommand("sm_realbhop_enabled 0");
		ServerCommand("sm_cvar sv_enablebunnyhopping 0");
		ServerCommand("sv_staminajumpcost .080");
		ServerCommand("sv_staminalandcost .050");
		ServerCommand("sv_airaccelerate 12");
		g_bhopenabled[client] = false;
		CPrintToChat(client, ">> {darkred}Bhop Disabled");
		return Plugin_Handled;
	}
}
*/





//Clear Global Chat
public Action:ClearChat(client, args)
{
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	CPrintToChatAll("");
	return Plugin_Handled;
}

//Clear Local Chat
public Action:ClearLocalChat(client, args)
{
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	CPrintToChat(client, "");
	return Plugin_Handled;
}