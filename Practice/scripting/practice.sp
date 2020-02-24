#includes <sourcemod>
#includes <colors>
#includes <sdktools>

public Plugin:myinfo =
{
  name = "Practice"
  author = "NeXz"
  description = "Features a set of commands which enable the practice of smokes and wall-bangs"
  version = "1"
  url = "steamcommunity.com/id/ollynexz"
}

public OnPluginStart()
{
  AddCommandListener(Practice, "practice")
}

public Action:Practice(client, const String:command[], args)
{
  ClientCommand(client, "practice");
  return Plugin_Handled;
}

stock bool IsValidClient(int client)
{
  if(client <= 0) return false;
  if(client > MaxClients) return false;
  if(!IsClientsConnected(client)) return false;
  return IsClientInGame(client);
}
